*** Settings ***
Documentation   Project For Robocorp Level II Course.
...             This project will download the order's file from the internet.
...             After it downloaded, the robot will automatic placing the order for you.
...             It will record the receipt and take a screenshot then save as a PDF file for each order.
...             At the end, all the PDF files will be ZIP.
Library         RPA.Robocorp.Vault
Library         RPA.Browser.Selenium
Library         RPA.HTTP
Library         RPA.Tables
Library         RPA.PDF
Library         RPA.Archive
Library         RPA.Dialogs


*** Variables ***
${retry_timeout}=   0.1 s
${retry_attemp}=    100 x

*** Keywords ***
Confirm The Website
    [Arguments]     ${website}
    Add icon    Warning
    Add heading    Confirm to download file from ${website}[URL] ?
    Add heading    If "No", the program will be terminate.  size=small
    Add submit buttons    Yes,No     default=Yes
    ${result}=    Run dialog    title=Confirmation  height=360  width=550
    
    IF    $result.submit == "Yes"
        Download    ${website}[URL]  overwrite=True
    ELSE
        Terminate All Processes
    END

*** Keywords ***
Download And Read The Orders
    ${s}=   Get Secret  web
    Confirm The Website     ${s}

***** Keywords ***
Open The Browser And Go To Order Page
    Open Available Browser  https://robotsparebinindustries.com/#/
    Maximize Browser Window
    Click Link    Order your robot!
    Click Button When Visible    css:.btn.btn-dark

*** Keywords ***
Fill The Form
    [Arguments]  ${order}
    ${head}=    Convert To Integer  ${order}[Head]
    ${body}=    Convert To Integer  ${order}[Body]
    ${legs}=    Convert To Integer  ${order}[Legs]
    Select From List By Value    head   ${head}
    Select Radio Button     body    ${body}
    Input Text  xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input   ${legs}
    Input Text  address    ${order}[Address]

*** Keywords ***
Preview The Order
    Click Button    preview
    Wait Until Element Is Visible    robot-preview-image

*** Keywords ***
Place The Order
    Click Button    order
    Wait Until Element Is Visible    receipt

*** Keywords ***
Preview And Place The Order
    Wait Until Keyword Succeeds  ${retry_attemp}     ${retry_timeout}    Preview The Order
    Wait Until Keyword Succeeds  ${retry_attemp}     ${retry_timeout}    Place The Order

*** Keywords ***
Place New Order
    Click Button When Visible    order-another
    Click Button When Visible    css:.btn.btn-dark

*** Keywords ***
Place A New Order
    Wait Until Keyword Succeeds  ${retry_attemp}     ${retry_timeout}    Place New Order

*** Keywords ***
Store Receipt And Screenshot In PDF
    [Arguments]     ${order_number}
    Wait Until Element Is Visible    receipt
    ${order_number}=    Get Text    xpath:/html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    ${receipt_html}=     Get Element Attribute   receipt     outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    Sleep   0.5s
    ${screenshot}=   Capture Element Screenshot    robot-preview  ${order_number}.png
    Open Pdf    ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    Add Watermark Image To Pdf    ${screenshot}     ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf
    Close Pdf   ${CURDIR}${/}output${/}receipts${/}${order_number}.pdf

*** Keywords ***
Zipping
    Archive Folder With Zip    ${CURDIR}${/}output${/}receipts    ${CURDIR}${/}output${/}orders.zip

*** Tasks ***
All Tasks to get Robocorp Level II course
    Download And Read The Orders
    ${orders}=  Read table from CSV    orders.csv   dialect=excel   header=True
    Open The Browser And Go To Order Page
    
    FOR  ${theorder}  IN  @{orders}
        Fill The Form   ${theorder}
        Preview And Place The Order
        Store Receipt And Screenshot In PDF    ${theorder} 
        Place A New Order
    END
    
    Zipping
    [Teardown]  Close Browser
