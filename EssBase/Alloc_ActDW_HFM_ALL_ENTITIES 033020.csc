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
This provides a weighting of the allocation based on the product's DW sales.  Equipment is allocated first, followed by all other Products.
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
FIX ("Wrkng", "FY20", "Jan", "LOC", @Relative("NetSlsNet",0), @Relative("CostGoodsSold",0))
FIX (@Relative("Multisite",0))  /* ***** this FIX for testing only to limit AGG  *****  */

/* -----  Aggregate Sparse dimensions for DW loads   ----- */
FIX("ACTDW", "SourceSys")
AGG ("Product");
ENDFIX 

/* -----  Aggregate Sparse dimensions for DW loads   ----- */
FIX("ACTDRADJ", "SourceSys")
AGG ("Product", "Brand", "Vendor", "Customer", "Analysis");
ENDFIX 

/* FIX("ACTDWADJ", "SourceSys", "Branded", "Branded","B_HSCHEIN","Local Exclusive", "B_OTHER_OWNED")
AGG ("Product", "Vendor", "Customer", "Analysis");
ENDFIX */

/* -----  Aggregate Product for HFM loads   ----- */
FIX ("ACTASRPD", "ACTELIM", "NonGPS", "Unspecified_Brand", "Oth_XX", "Unspecified_Vendor", "SourceSys")
AGG("Product");
ENDFIX

/*  Actual Allocation */
SET CREATEBLOCKONEQ ON;

/*  FIX (@Relative("Multisite",0))  */
FIX(@RELATIVE("Analysis",0), @RELATIVE("Brand",0), @RELATIVE("Customer",0), @RELATIVE("Product",0), @RELATIVE("Vendor",0))
         "ACTALLOC" (
          IF(@ISDESC("Equipment"))
          IF(@ISDESC("NetSlsNet"))
          "ACTALLOC" =(("ActAsRpd"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet"
          		+ "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                        
                     - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                     +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet" ))

                     /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"NetSlsNet")

                     * ("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;

     	  ELSEIF(@ISDESC("CostGoodsSold"))
          "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold"
         			 + "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Equipment"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
                     
                      - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Equipment"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Equipment"->"TotalVendor"->"SourceSys"->"CostGoodsSold")

                      *("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;
           ENDIF;
           ENDIF;
           
           IF (@ISDESC("Merchandise"))
           IF(@ISDESC("NetSlsNet"))
    
          "ACTALLOC" =(("ActAsRpd"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Merchandise"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet"
          				+ "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Merchandise"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                        
                     - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Merchandise"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                     +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"NetSlsNet" ))

                     /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Merchandise"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"NetSlsNet")

                     * ("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;

     	  ELSEIF(@ISDESC("CostGoodsSold"))
          "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Merchandise"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold"
         		 + "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Merchandise"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
                     
                      - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Merchandise"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Merchandise"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Merchandise"->"TotalVendor"->"SourceSys"->"CostGoodsSold")

                      *("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;
            ENDIF;
            ENDIF;
            
		    IF(@ISDESC("Value Added Services"))
           	IF(@ISDESC("NetSlsNet"))
    
          "ACTALLOC" =(("ActAsRpd"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Value Added Services"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet"
          				+ "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Value Added Services"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                        
                     - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Value Added Services"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                     +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"NetSlsNet" ))

                     /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Value Added Services"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"NetSlsNet")

                     * ("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;

     	  	ELSEIF(@ISDESC("CostGoodsSold"))
          "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Value Added Services"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold"
         		+ "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Value Added Services"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
                     
                      - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Value Added Services"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      /  ("ActDW"->"TotalAnalysis"->"NOAPPBE"->"NOAPPCX"->"Value Added Services"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Value Added Services"->"TotalVendor"->"SourceSys"->"CostGoodsSold")

                      *("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;   
            ENDIF;
            ENDIF;
                   
           	IF(@ISDESC("Technology"))
          	IF(@ISDESC("NetSlsNet"))
    
          "ACTALLOC" =(("ActAsRpd"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Technology"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet"
          				+ "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Technology"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                        
                     - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Technology"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                     +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"NetSlsNet" ))

                     /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Technology"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"NetSlsNet")

                     * ("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;

     	  	ELSEIF(@ISDESC("CostGoodsSold"))
          "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Technology"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold"
         			 + "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Technology"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
                     
                      - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Technology"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Technology"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Technology"->"TotalVendor"->"SourceSys"->"CostGoodsSold")

                      *("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;
            ENDIF;
            ENDIF;
            
            IF(@ISDESC("MedicalProducts"))
          	IF(@ISDESC("NetSlsNet"))
    
          "ACTALLOC" =(("ActAsRpd"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"MedicalProducts"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet"
          				+ "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"MedicalProducts"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                        
                     - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"MedicalProducts"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                     +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"NetSlsNet" ))

                     /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"MedicalProducts"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"NetSlsNet")

                     * ("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;

     	  ELSEIF(@ISDESC("CostGoodsSold"))
          "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"MedicalProducts"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold"
         			 + "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"MedicalProducts"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
                     
                      - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"MedicalProducts"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"MedicalProducts"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"MedicalProducts"->"TotalVendor"->"SourceSys"->"CostGoodsSold")

                      *("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;
            ENDIF;
            ENDIF;
          
            IF(@ISMBR ("Unspecified_Product"))
           	IF(@ISDESC("NetSlsNet"))
    
          "ACTALLOC" =(("ActAsRpd"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Unspecified_Product"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet"
          				+ "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Unspecified_Product"->"Unspecified_Vendor"->"SourceSys"->"NetSlsNet")
                        
                     - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Unspecified_Product"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                     +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"NetSlsNet" ))

                     /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Unspecified_Product"->"NOAPPVN"->"SourceSys"->"NetSlsNet"
                     +   "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"NetSlsNet"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"NetSlsNet")

                     * ("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                     +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;

     	  ELSEIF(@ISDESC("CostGoodsSold"))
          "ACTALLOC" =(("ActAsRpd" ->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Unspecified_Product"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold"
         			 + "ACTELIM"->"NonGPS"->"Unspecified_Brand"->"Oth_XX"->"Unspecified_Product"->"Unspecified_Vendor"->"SourceSys"->"CostGoodsSold")
                     
                      - ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Unspecified_Product"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"CostGoodsSold"))

                      /  ("ActDW"->"NOAPPAN"->"NOAPPBE"->"NOAPPCX"->"Unspecified_Product"->"NOAPPVN"->"SourceSys"->"CostGoodsSold"
                      +  "ActDRAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"CostGoodsSold"
                      +  "ActDWAdj"->"TotalAnalysis"->"TotalBrand"->"TotalCustomer"->"Unspecified_Product"->"TotalVendor"->"SourceSys"->"CostGoodsSold")

                      *("ActDW"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDRAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys"
                      +  "ActDWAdj"->@CURRMBR("Analysis")->@CURRMBR("Brand")->@CURRMBR("Customer")->@CURRMBR("Product")->@CURRMBR("Vendor")->"SourceSys") ;
            ENDIF;
            ENDIF;)  

		ENDFIX
        ENDFIX
        ENDFIX
        
SET CREATEBLOCKONEQ OFF;

/* Currency Conversion */
/* FIX ("ACTALLOC", "WRKNG", "FY18", "FY19", "FY20",  @Relative("Yr",0), "SourceSys", @RELATIVE("TotalCustomer",0), @RELATIVE("TotalBrand",0),
@RELATIVE("TotalProduct",0),@RELATIVE("TotalVendor",0),@RELATIVE("Analysis",0))  */

/* 1) Currency Conversion: USD and Constant Currency.  Entity members are calculated using the @Attribute function. */
/* FIX (@Relative("NetSlsNet",0), @Relative("CostGoodsSold",0), @ATTRIBUTE("LPC"))
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

*/



/*ENDCOMPONENT*/
  