<#
    .NOTES
    ===========================================================================
     Created by:       Alan Callahan
     Assisted by:      ChatGPT / Copilot
     Modified on:       4/15/2023
     Filename:         CommonCSS.psm1
     Version:          Beta 1.0
    ===========================================================================
    .DESCRIPTION
    This module contains the common CSS used in the HTML reports.
#>

function Get-CommonCSS {
    return @"
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 0;
        }

        header {
            background-color: #0070AD;
            color: white;
            text-align: center;
            padding: 1rem;
            font-size: 1.5rem;
        }

        main {
            padding: 2rem;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin-bottom: 2rem;
        }
        
        th, td {
            border: 1px solid #ccc;
            padding: 0.5rem;
            text-align: left;
        }
        
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        
        .warning {
            background-color: yellow;
        }
        
        .danger {
            background-color: red;
        }
        
        .company-info {
            padding: 1rem;
            font-size: 0.9rem;
        }
        
        .company-logo {
            float: left;
            height: 50px;
            padding-right: 1rem;
        }
"@
}
