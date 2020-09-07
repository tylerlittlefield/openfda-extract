
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
To avoid duplication, I have tried to store nested data in different
tables:

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
    -   Postgres database hosted on a digital ocean droplet.
    -   2 GB Memory, 2 vCPUs, 60 GB Disk, Ubuntu 18.04.3 (LTS) x64.

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
      select(text) %>% 
      head(1)
    #> # Source:   lazy query [?? x 1]
    #> # Database: postgres [tyler@localhost:/openfda]
    #>   text                                                                          
    #>   <chr>                                                                         
    #> 1 IT WAS REPORTED THAT A LOW TRANSMITTER BATTERY ALERT OCCURRED. DATA WAS EVALU…

    # query the device information
    tbl(con, "adverse_events.device") %>% 
      filter(manufacturer_d_name == "ETHICON, INC.") %>% 
      glimpse()
    #> Rows: ??
    #> Columns: 38
    #> Database: postgres  [tyler@localhost:/openfda]
    #> $ id                                    <chr> "1997q1-0001-0001-3114", "1997q…
    #> $ lot_number                            <chr> "UNK", "JME720", "*", "JHE252",…
    #> $ manufacturer_d_country                <chr> "US", "US", "US", "US", "US", "…
    #> $ manufacturer_d_zip_code_ext           <chr> "0151", "0151", "", "0151", "01…
    #> $ manufacturer_d_postal_code            <chr> "", "", "", "", "", "", "", "",…
    #> $ device_event_key                      <chr> "67655", "75697", "71933", "767…
    #> $ baseline_510_k__exempt_flag           <chr> "N", "N", "", "", "N", "N", "N"…
    #> $ device_operator                       <chr> "HEALTH PROFESSIONAL", "HEALTH …
    #> $ generic_name                          <chr> "ABSORBABLE SUTURE", "NON-ABSOR…
    #> $ model_number                          <chr> NA, NA, "*", NA, NA, NA, NA, NA…
    #> $ date_received                         <chr> "19970206", "19970314", "199702…
    #> $ device_evaluated_by_manufacturer      <chr> "R", "N", "", "Y", "Y", "N", "Y…
    #> $ manufacturer_d_zip_code               <chr> "08876", "08876", "08576", "088…
    #> $ baseline_510_k__flag                  <chr> "Y", "N", "", "", "N", "N", "Y"…
    #> $ device_sequence_number                <chr> "1", "1", "1", "1", "1", "1", "…
    #> $ device_age_text                       <chr> "UNKNOWN", "3 MO", "", "*", "7 …
    #> $ brand_name                            <chr> "COATED VICRYL (POLYGLACTIN 910…
    #> $ baseline_510_k__number                <chr> "K946271", "", "", "", "", "", …
    #> $ manufacturer_d_state                  <chr> "NJ", "NJ", "NJ", "NJ", "NJ", "…
    #> $ other_id_number                       <chr> NA, NA, "*", NA, NA, NA, NA, NA…
    #> $ implant_flag                          <chr> "Y", "Y", "Y", "Y", "Y", "Y", "…
    #> $ manufacturer_d_address_2              <chr> "", "", "", "", "", "", "", "",…
    #> $ catalog_number                        <chr> "J232H", "M8718", "*", "8707H",…
    #> $ manufacturer_d_address_1              <chr> "P.O. BOX 151", "P.O. BOX 151",…
    #> $ manufacturer_d_city                   <chr> "SOMERVILLE", "SOMERVILLE", "SO…
    #> $ manufacturer_d_name                   <chr> "ETHICON, INC.", "ETHICON, INC.…
    #> $ device_availability                   <chr> "No", "Device was returned to m…
    #> $ date_removed_flag                     <chr> "V", "V", "V", "V", "Not availa…
    #> $ device_report_product_code            <chr> "GAM", "GAW", "FTM", "GAW", "GA…
    #> $ openfda.regulation_number             <chr> "878.4493", "878.5010", "878.33…
    #> $ openfda.medical_specialty_description <chr> "General, Plastic Surgery", "Ge…
    #> $ openfda.device_class                  <chr> "2", "2", "2", "2", "2", "2", "…
    #> $ openfda.device_name                   <chr> "Suture, Absorbable, Synthetic,…
    #> $ date_returned_to_manufacturer         <chr> NA, NA, NA, NA, NA, NA, NA, "19…
    #> $ expiration_date_of_device             <chr> NA, NA, NA, "20010701", NA, NA,…
    #> $ openfda.fei_number                    <chr> "", "", "", "", "", "", "", "",…
    #> $ openfda.registration_number           <chr> "", "", "", "", "", "", "", "",…
    #> $ device                                <chr> "", "", "", "", "", "", "", "",…

    # disconnect
    dbDisconnect(con)

Note that there is an `id` column in every table, for example:

-   `2014q4-0002-0003-3683`
-   `<year quarter>-<part n>-<n parts>-<row number>`

I made this column so that tables can be joined (though this ID in some
other form might already exist in the data, I just haven’t figured out
if that is the case or not).
