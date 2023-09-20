*** Comments ***
# The robot should use the orders file (.csv ) and complete all the orders in the file.
# Only the robot is allowed to get the orders file. You may not save the file manually on your computer.
# The robot should save each order HTML receipt as a PDF file.
# The robot should save a screenshot of each of the ordered robots.
# The robot should embed the screenshot of the robot to the PDF receipt.
# The robot should create a ZIP archive of the PDF receipts (one zip archive that contains all the PDF files). Store the archive in the output directory.
# The robot should complete all the orders even when there are technical failures with the robot order website.
# The robot should be available in public GitHub repository.
# It should be possible to get the robot from the public GitHub repository and run it without manual setup.

# Created by sidharth Saini


*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.


Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.PDF
Library             RPA.HTTP
Library             RPA.Tables
Library             OperatingSystem
Library             DateTime
Library             Dialogs
Library             Screenshot
Library             RPA.Archive
Library             RPA.Robocorp.Vault


*** Variables ***
${receipt_directory}=       ${OUTPUT_DIR}${/}receipts${/}
${image_directory}=         ${OUTPUT_DIR}${/}images${/}
${zip_directory}=           ${OUTPUT_DIR}${/}
${name_of_zip}=    Zip_of_Orders.zip


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Get orders
    Open the robot order website
    Fill in the order form using the data from the csv file
    Name and make the ZIP
    Delete original images
    Log out and close the browser


*** Keywords ***
Get orders
    Download the csv file    https://robotsparebinindustries.com/#/robot-order

Download the csv file
    [Arguments]    ${csv_url}
    Download    ${csv_url}    overwrite=True

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Close the annoying modal
    Wait Until Page Contains Element    class:alert-buttons
    Click Button    OK

Make order
    Click Button    Order
    Page Should Contain Element    id:receipt

Return to order form
    Wait Until Element Is Visible    id:order-another
    Click Button    id:order-another

Fill the form
    [Arguments]    ${row}
    Close the annoying modal
    Wait Until Page Contains Element    class:form-group
    Select From List By Index    head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${row}[Legs]
    Input Text    address    ${row}[Address]
    Click Button    Preview
    Wait Until Keyword Succeeds    2min    500ms    Make order

Store the receipt as a PDF file
    Wait Until Element Is Visible    id:receipt
    ${order_id}=    Get Text    //*[@id="receipt"]/p[1]
    Set Local Variable    ${receipt_filename}    ${receipt_directory}receipt_${order_id}.pdf
    ${receipt_html}=    Get Element Attribute    //*[@id="receipt"]    outerHTML
    Html To Pdf    content=${receipt_html}    output_path=${receipt_filename}

    Wait Until Element Is Visible    id:robot-preview-image
    Set Local Variable    ${image_filename}    ${image_directory}robot_${order_id}.png
    Screenshot    id:robot-preview-image    ${image_filename}
    Embed the robot screenshot to the receipt PDF file    ${receipt_filename}    ${image_filename}

Fill in the order form using the data from the csv file
    ${orders}=    Read table from CSV    path=orders.csv
    FOR    ${order}    IN    @{orders}
        Fill the form    ${order}
        Store the receipt as a PDF file
        Return to order form
    END

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${receipt_filename}    ${image_filename}
    Open PDF    ${receipt_filename}
    @{pseudo_file_list}=    Create List
    ...    ${receipt_filename}
    ...    ${image_filename}:align=center

    Add Files To PDF    ${pseudo_file_list}    ${receipt_filename}    ${False}
    Close Pdf    ${receipt_filename}

Log out and close the browser
    Close Browser

Delete original images
    Empty Directory    ${image_directory}
    Empty Directory    ${receipt_directory}

Name and make the ZIP
    Log To Console    ${name_of_zip}
    Create the ZIP    ${name_of_zip}

Create the ZIP
    [Arguments]    ${name_of_zip}
    Create Directory    ${zip_directory}
    Archive Folder With Zip    ${receipt_directory}    ${zip_directory}${name_of_zip}
