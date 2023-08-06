*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.Excel.Files
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Download the CSV File
    Open the robot order website
    Get Order
    Create ZIP package from PDF files
    Close the browser
    [Teardown]
    ...    Cleanup temporary PDF directory


*** Keywords ***
Open the robot order website
    # ToDo: Implement your keyword here
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Sleep    3s

Download the CSV File
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Fill the form
    [Arguments]    ${row}
    Click Button    OK
    # Sleep    3s
    Wait Until Element Is Visible    id:head
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://*[contains(@placeholder, "Enter the part number for the legs")]    ${row}[Legs]
    Input Text    address    ${row}[Address]
    # Sleep    2s
    Click Button    preview
    # Sleep    10s
    Wait Until Element Is Visible    xpath://*[@id='robot-preview-image']
    Wait Until Element Is Visible    xpath://*[@id='robot-preview']/p[1]

    FOR    ${counter}    IN RANGE    1    20
        Log    ${counter}
        TRY
            Click Button    order
            Wait Until Element Is Visible    xpath://*[@id='order-completion']/div[1]
            Log    Order button clicked at TRY
            BREAK
        EXCEPT
            Log    Continue at Except
            CONTINUE
        END
    END

    Sleep    3s
    ${index}=    Set Variable    ${row}[Head]${row}[Body]${row}[Legs]

    ${sales_results_html}=    Get Element Attribute    xpath://div[contains(@class, 'alert-success')]    outerHTML
    Screenshot    xpath://*[@id='robot-preview']/div[1]    filename=${CURDIR}/output/screenshot/Screenshot_${index}.png

    ${sales_results_html}=    Set Variable
    ...    ${sales_results_html}<br><br><img src=${CURDIR}/output/screenshot/Screenshot_${index}.png>
    Log    ${sales_results_html}
    Html To Pdf    ${sales_results_html}    ${CURDIR}/output/pdf/doc_${index}.pdf    overwrite=${True}

    Click Button    order-another

Create ZIP package from PDF files
    ${zip_file_name}=    Set Variable    ${CURDIR}${/}PDFs.zip
    Log    ${CURDIR}${/}output${/}pdf
    Archive Folder With Zip    ${CURDIR}${/}output/pdf    ${zip_file_name}

Cleanup temporary PDF directory
    Log    File Deleted Excecuted
    Remove Directory    ${CURDIR}/output/pdf    True
    Remove Directory    ${CURDIR}/output/screenshot    True

Close the browser
    Close Browser

Get Order
    Create Dictionary    ${CURDIR}/output/pdf    True
    Create Dictionary    ${CURDIR}/output/screenshot    True
    ${orders}=    Read table from CSV    orders.csv
    Log    Reading CSV FILE

    FOR    ${row}    IN    @{orders}
        Log    Start Rows Data : ${row}
        TRY
            # Open the robot order website
            Fill the form    ${row}
            # Close the browser
        EXCEPT
            # Close the browser
            CONTINUE
        END
        Log    End Rows Data: ${row}
    END
