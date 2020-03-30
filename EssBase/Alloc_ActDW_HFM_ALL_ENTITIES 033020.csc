/*STARTCOMPONENT:SCRIPT*/
/*
Script: Alloc_ActDW_HFM by Product weight
Description: Allocate difference between HFM and DW using the ACTALLOC scenario, followed by currency translation.
   - Allocation at Equipment rollup of the Product dimension
   - Allocation of all other Product data
Sub Variables / RTPs: {rtpEntity}, {rtpYear}
Steps / Additional Information:
1) Aggregation
2) Actuals Allocation at ACTALLOC = ((Total HFM total – (Total DW + Total Direct Adjustments) / (Total DW + Total Direct Adjustments)) x (Current Member DW + Direct Adjustments)
This provides a weighting of the allocation based on the product's DW sales.  
Modified: Scott Ross, 032920, reviewed and corrected. ObjectAccounts needed Dynamic Calc parent members.  
*/

SET MSG SUMMARY;
SET AGGMISSG OFF;
SET UPDATECALC OFF;
SET CALCPARALLEL 12;
SET CALCTASKDIMS 1;
SET FRMLBOTTOMUP ON;
SET CACHE HIGH;

/*  Global Fix */
FIX ("Wrkng", "FY18","FY19","FY20", @Relative("Yr",0), "LOC", @Relative("NetSlsNet",0), @Relative("CostGoodsSold",0))
FIX (@Relative("GlobalDent",0), @Relative("NARConsFed",0), @Relative("ProRepairCons",0), @Relative("ExportGrpCons",0))

/*   Aggregate Product for ACTDW data loads */
FIX ("ACTDW", "NOAPPAN", "NOAPPBE", "NOAPPCX", "NOAPPVN", "SourceSys" )
AGG ("Product");
ENDFIX 

/* -----  Aggregate Sparse dimensions for DW Adjustments   ----- */
FIX("ACTDWADJ", "ACTDRADJ", "SourceSys")
AGG ("Product", "Brand", "Vendor", "Customer", "Analysis");
ENDFIX 

/* -----  Aggregate Product for HFM loads   ----- */
FIX ("ACTASRPD", "NonGPS", "Unspecified_Brand", "Oth_XX", "Unspecified_Vendor", "SourceSys")
AGG("Product");
ENDFIX

/*  Actual Allocation */

FIX(@RELATIVE("Analysis",0), @RELATIVE("Brand",0), @RELATIVE("Customer",0), @RELATIVE("Product",0), @RELATIVE("Vendor",0))
         "ACTALLOC" (
          IF(@ISDESC("Equipment"))
          IF(@ISDESC("NetSlsNet"))
          "ACTALLOC" =(("ActAsRpd"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
          				
                     - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                     +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet" ))

                     /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet")

                     * (("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys")) ;

          ELSEIF(@ISDESC("CostGoodsSold"))
          "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
         			 
                      - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold")

                      *(("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys")) ;
           ENDIF
           ELSE
           IF(@ISDESC("NetSlsNet"))
           "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"TotalProduct"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet"
                       -  "ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                      
                       - (("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"TotalProduct"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                       -  "ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"NetSlsNet")
                       + ("ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                       -  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet")
                       + ("ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                       - "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet"))

                       / (("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"TotalProduct"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                       -  "ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN" ->"SourceSys"->"NetSlsNet")
                       +  ("ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                       -   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                       + ("ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                       - "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet"))

                       *("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys")) ;

            ELSEIF(@ISDESC("CostGoodsSold"))
           "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"TotalProduct"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold"
                      -  "ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
                     
                      - (("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"TotalProduct"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      -  "ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"CostGoodsSold")
                      + ("ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                     -  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold")
                     + ("ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                       - "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold")))

                       / (("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"TotalProduct"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                        -  "ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NoAppVn"->"SourceSys"->"CostGoodsSold")
                       +  ("ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                       -   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold")
                       + ("ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"TotalProduct"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                       - "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      * (("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys")) ;
            ENDIF
            ENDIF ;
         )

         ENDFIX
         ENDFIX
         ENDFIX

/* Currency Conversion */
FIX ("ACTALLOC", "WRKNG", "FY18", "FY19", "FY20",  @Relative("Yr",0), "SourceSys", @RELATIVE("TotalCustomer",0), @RELATIVE("TotalBrand",0),
@RELATIVE("TotalProduct",0),@RELATIVE("TotalVendor",0),@RELATIVE("Analysis",0))

/* 1) Currency Conversion: USD and Constant Currency.  Entity members are calculated using the @Attribute function. */
FIX (@Relative("NetSlsNet",0), @Relative("CostGoodsSold",0), @ATTRIBUTE("LPC"))
    DATACOPY "LOC" TO "USD";
    DATACOPY "LOC" TO "USD_CYBR";

    "USD" (@CALCMODE(BLOCK);@CALCMODE(BOTTOMUP);
    IF (NOT @ISATTRIBUTE("LPC_USD"))
    IF (NOT @ISUDA("ObjectAccount","NOCONV"))
        @MEMBER(@SUBSTRING(@ATTRIBUTESVAL(LPC),4)) = "USD";
        "USD" = @ROUND("USD" /
        @MEMBER(@SUBSTRING(@ATTRIBUTESVAL(LPC),4))->"ACTASRPD"->"WRKNG"->"AVGRate"->"NOAPPAN"->"NOAPPCX"->"NOAPPBE"->"NOAPPENTITY"->"NOAPPPD"->"NOAPPVN"->"SourceSys",5);
        "USD_CYBR" = @ROUND("USD_CYBR" /
        @MEMBER(@SUBSTRING(@ATTRIBUTESVAL(LPC),4))->"BUDCY"->"WRKNG"->"AVGRate"->"NOAPPAN"->"NOAPPCX"->"NOAPPBE"->"NOAPPENTITY"->"NOAPPPD"->"NOAPPVN"->"SourceSys",5);
    ENDIF
    ENDIF);
ENDFIX
ENDFIX
