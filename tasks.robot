*** Settings ***
Documentation       Build and order a robot - RobotSpareBin Industries Inc

Library             RPA.HTTP
Library             RPA.Browser.Selenium    #auto_close=${False}
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Dialogs
Library             RPA.FileSystem
Library             RPA.Archive
Library             RPA.Desktop.OperatingSystem
Library             RPA.Robocorp.Vault
Library             Dialogs


*** Variables ***
${receipt_folder}       ${OUTPUT_DIR}${/}receipts${/}
${zip_folder}           ${OUTPUT_DIR}${/}


*** Tasks ***
Build and order a robot
    Download orders file
    Open website
    #Set Selenium Speed    0.3s
    FOR    ${order}    IN    @{orders}
        Log    ${order}
        Make an order    ${order}
        Save receipt
        Add another order
    END
    ZIP receipts
    Clear receipt folder
    [Teardown]    Close current browser


*** Keywords ***
Download orders file
    ${url_download}    Get Value From User    Insira o endereço do arquivo csv para download
    Download    ${url_download}
    ${orders}    Read table from CSV    orders.csv    header=True
    Set Global Variable    ${orders}

Open website
    ${url_site}    Get Secret    vault
    Open Available Browser    ${url_site}[url_site]    maximized=True

Make an order
    [Arguments]    ${order}
    Wait And Click Button    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:.form-control    ${order}[Legs]
    Input Text    id:address    ${order}[Address]
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image
    Click Button    id:order
    ${server_out}    Set Variable    False
    ${server_out}    Is Element Visible    css:.alert-danger
    WHILE    ${server_out} == True    limit=10
        Sleep    3s
        Click Button    id:order
        ${server_out}    Is Element Visible    css:.alert-danger
    END

Save receipt
    Wait Until Element Is Visible    id:receipt
    ${receipt_number}    Get Text    css:#receipt > p.badge.badge-success
    ${receipt_html}    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${receipt_folder}receipt_${receipt_number}.pdf
    Screenshot    id:robot-preview-image    ${receipt_folder}preview.png
    ${preview}    Create List    ${receipt_folder}preview.png
    Add Files To Pdf    ${preview}    ${receipt_folder}receipt_${receipt_number}.pdf    append=True
    Remove File    ${receipt_folder}preview.png

Add another order
    Sleep    2s
    Click Button    id:order-another

ZIP receipts
    ${datetime}    Get Boot Time    as_datetime=True    datetime_format=%Y%m%d_%H%M%S
    Archive Folder With Zip    ${receipt_folder}    receipt_${datetime}.zip

Clear receipt folder
    Empty Directory    ${receipt_folder}

Close current browser
    Close Browser
