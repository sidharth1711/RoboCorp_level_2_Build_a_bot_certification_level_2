*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library        RPA.Browser.Selenium    auto_close=${False}
Library        RPA.Tables
Library        RPA.HTTP
Library        RPA.PDF
Library    OperatingSystem

*** Variables ***
${CSV_File_URL}=    https://robotsparebinindustries.com/orders.csv
${file_name}=       orders.csv
${form_url}=        https://robotsparebinindustries.com/#/robot-order
*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders website
    Close the annoying modal
    ${orders}=  Get orders
        FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
        ${pdf}=    Store the order receipt as a PDF file    ${order}\[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}\[Order number]
        Embed The Robot Screenshot To The Receipt PDF File    ${order}
        END
*** Keywords ***
Open the robot orders website
    Download    ${CSV_File_URL}    overwrite=${True}
    [Documentation]    returns the order details from orders.csv
Get orders
    ${tbl}=  Read table from CSV  ${file_name}
    RETURN    ${tbl}
Close the annoying modal
    Open Available Browser  ${form_url}
    Maximize Browser Window
    Wait And Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
Fill the form    
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Click Element    id:id-body-${order}[Body]
    Input Text    class:form-control  ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Sleep    2
    TRY
        Click Button    id:order
    EXCEPT
        Sleep  3
        Click Button    id:order
    END
    
    # Click Element If Visible    class:alert alert-danger
    # Click Button    id:order

Store the order receipt as a PDF file    
    [Arguments]    ${order}
        Sleep    3
    Wait Until Element Is Visible  id:order-another
    ${order_receipt}    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt}    ${OUTPUT_DIR}${/}receipts${/}${order}\[Order number].pdf  overwrite=${True}
    RETURN  ${order_receipt}
Take a screenshot of the robot
    [Arguments]    ${order}
    Wait Until Element Is Visible    id:robot-preview-image
    Sleep  2
    ${scrnSht}=  Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}images${/}${order}[Order number].pdf
    RETURN  ${scrnSht}
    
Embed The Robot Screenshot To The Receipt PDF File
    [Arguments]  ${order}
    Open Pdf    ${OUTPUT_DIR}${/}${order}[Order number].PDF
    Add Watermark Image To PDF
    ...             image_path=${OUTPUT_DIR}${/}${order}\[Order number].pdf
    ...             source_path=${OUTPUT_DIR}${/}${order}\[Order number].PDF
    ...             output_path=${OUTPUT_DIR}${/}${order}${/}data${/}\[Order number].PDF
    Remove File    ${OUTPUT_DIR}${/}${order}[Order number].pdf
    Close Pdf