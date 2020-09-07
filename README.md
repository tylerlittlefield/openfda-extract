
<!-- README.md is generated from README.Rmd. Please edit that file -->

openfda-extract
===============

<!-- badges: start -->
<!-- badges: end -->

This repository collects [adverse events
data](https://open.fda.gov/apis/device/event/download/) from openFDA. A
single [script](/data-raw/loop.R) attempts to:

1.  Convert JSON files to tabular format using `jsonlite::fromJSON` and
    `tidyr::unnest`.
2.  Save the data to a database.

The data is relational as described
[here](https://opendata.stackexchange.com/a/2187). Converting the data
to tabular format may not be efficient and causes lots of duplication.
If you want to run this, you need to have a database ready, some storage
space, and patience. I have split the nested data into separate tables,
in total:

1.  `adverse_events`
2.  `adverse_events.mdr_text`
3.  `adverse_events.product_problems`
4.  `adverse_events.source_type`
5.  `adverse_events.device`
6.  `adverse_events.patient`
7.  `adverse_events.remedial_action`
8.  `adverse_events.type_of_report`

Where the naming convention is `mainframe.<list col>`.

Hardware
--------

1.  I transformed the data on:
    -   2013 15" MacBook Pro, 8 GB Memory, 8 Core CPU.
2.  I wrote the data to:
    -   Postgres database hosted on a digital ocean droplet
    -   2 GB Memory, 2 vCPUs, 60 GB Disk, Ubuntu 18.04.3 (LTS) x64

For context, this was the result of my first run:

    ~ openFDA database refresh completed in [17.4161201466454 hours]

Examples
--------

If you have successfully ran everything, you should have 8 tables with
millions of observations that you can explore.

    library(dplyr, warn.conflicts = FALSE)
    library(DBI)

    # credentials
    dw <- config::get("datawarehouse")

    # connect to db
    con <- DBI::dbConnect(
      odbc::odbc(),
      Driver = dw$driver,
      Server = dw$server,
      Database = dw$database,
      UID = dw$uid,
      PWD = dw$pwd,
      Port = dw$port
    )

    # list all available tables
    dbListTables(con)
    #> [1] "adverse_events"                  "adverse_events.device"          
    #> [3] "adverse_events.mdr_text"         "adverse_events.patient"         
    #> [5] "adverse_events.product_problems" "adverse_events.remedial_action" 
    #> [7] "adverse_events.source_type"      "adverse_events.type_of_report"

    # query the mdr text
    tbl(con, "adverse_events.mdr_text") %>% 
      select(id, text)
    #> # Source:   lazy query [?? x 2]
    #> # Database: postgres [tyler@localhost:/openfda]
    #>    id               text                                                        
    #>    <chr>            <chr>                                                       
    #>  1 1996q1-0001-000… "PT WITH HISTORY OF PELVIC PAIN. LAPAROSCOPIC ASSISTED VAGI…
    #>  2 1996q1-0001-000… "ON TUESDAY, 12/26, RPTR WENT TO THE PT'S HOME AND THE RPTR…
    #>  3 1996q1-0001-000… "FACILITY ALLEGES PT REACTION DURING DIALYSIS. CHIEF TECH R…
    #>  4 1996q1-0001-000… "PT SUFFERED A SUPRACONDYLAR FRACTURE OF THE RIGHT FEMUR WI…
    #>  5 1996q1-0001-000… "PLASTIC SPIKE ATTACHED TO DRIP CHAMBER APPEARS TO HAVE A B…
    #>  6 1996q1-0001-000… "DENTAL IMPLANT FAILED IN FUNCTION."                        
    #>  7 1996q1-0001-000… "WHILE PREPARING FOR A CRYOSURGICAL PROCEDURE THE STAFF DET…
    #>  8 1996q1-0001-000… "PICC LINE INSERTED. A SMALL \"PIN\" HOLE WAS NOTED AT THE …
    #>  9 1996q1-0001-000… "DURING USE, RECIPROCATING SAW LEAKED BLACK FLUID INTO PT'S…
    #> 10 1996q1-0001-000… "PT COMPLAINED OF PAIN. IT WAS FOUND THAT THE PLASTIC HAD S…
    #> # … with more rows

    # query the device information
    tbl(con, "adverse_events.device") %>% 
      select(id, manufacturer_d_name)
    #> # Source:   lazy query [?? x 2]
    #> # Database: postgres [tyler@localhost:/openfda]
    #>    id                  manufacturer_d_name                   
    #>    <chr>               <chr>                                 
    #>  1 1996q1-0001-0001-1  ETHICON, INC.                         
    #>  2 1996q1-0001-0001-2  SIMS DELTEC, INC.                     
    #>  3 1996q1-0001-0001-3  TERUMO MEDICAL CORP.                  
    #>  4 1996q1-0001-0001-4  SMITH & NEPHEW RICHARDS, INC.         
    #>  5 1996q1-0001-0001-5  CURRIE MEDICAL SPECIALTIES            
    #>  6 1996q1-0001-0001-6  CORE-VENT BIO-ENGINEERING             
    #>  7 1996q1-0001-0001-7  CRYOGENIC TECHNOLOGIES, LTD.          
    #>  8 1996q1-0001-0001-8  GESCO INTERNATIONAL, INC.             
    #>  9 1996q1-0001-0001-9  STRYKER INSTRUMENTS DIV. STRYKER CORP.
    #> 10 1996q1-0001-0001-10 ZIMMER,INC.                           
    #> # … with more rows

    # disconnect
    dbDisconnect(con)

Note that there is an `id` column in every table, for example:

-   `2014q4-0002-0003-3683`
-   `<year quarter>-<part n>-<n parts>-<row number>`

I made this column so that tables can be joined (though this ID in some
other form might already be available in the data, I just haven’t
figured it out). already)
