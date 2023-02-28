*** Settings ***
# Boilerplate
Suite Setup       Setup
Suite Teardown    Teardown
Test Setup        Reset Emulation
Resource          ${RENODEKEYWORDS}

*** Variables ***
${LOGIN_PROMPT}  buildroot login:

*** Keywords ***
Start Test
    Execute Command     set bbl @${BBL}
    Execute Command     set fdt @${FDT}
    Execute Command     set kernel @${KERNEL}

    Execute Command     include @${MACHINFO}
    Execute Command     runMacro "$reset"

    Create Terminal Tester sysbus.uart0
    Start Emulation

*** Test Cases ***
Boot Up
    [Documentation]             Just a simple test

    Start Test

    Wait For Prompt On Uart ${LOGIN_PROMPT}
    Write Line To Uart root
    Write Line To Uart root

    Write Line To Uart uname
    Wait For Line On Uart Linux
