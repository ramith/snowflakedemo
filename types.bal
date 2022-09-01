import ballerina/sql;

# Represents an entry a sales summary
type PricingSummary record {|
    @sql:Column {name: "l_returnflag"}
    string returnFlag;

    @sql:Column {name: "l_linestatus"}
    string lineStatus;

    @sql:Column {name: "sum_qty"}
    int totalQuantity;

    @sql:Column {name: "sum_base_price"}
    int totalOfExtendedPrice;

    @sql:Column {name: "sum_disc_price"}
    int totalOfDiscountedExtendedPrice;

    @sql:Column {name: "sum_charge"}
    int totalOfDiscountedExtendedPricePlusTax;

    @sql:Column {name: "avg_qty"}
    decimal averageQuantity;

    @sql:Column {name: "avg_price"}
    decimal averageExtendedPrice;

    @sql:Column {name: "avg_disc"}
    decimal averageDiscount;

    @sql:Column {name: "count_order"}
    int totalLineItems;
|};

# Represents a line item in SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM
type LineItem record {
    @sql:Column {name: "L_ORDERKEY"}
    int orderKey;

    @sql:Column {name: "L_PARTKEY"}
    int partKey;

    @sql:Column {name: "L_SUPPKEY"}
    int supplierKey;

    @sql:Column {name: "L_LINENUMBER"}
    int lineNumber;

    @sql:Column {name: "L_QUANTITY"}
    int quantity;

    @sql:Column {name: "L_EXTENDEDPRICE"}
    decimal extendedPrice;

    @sql:Column {name: "L_DISCOUNT"}
    decimal discount;

    @sql:Column {name: "L_TAX"}
    decimal tax;

    @sql:Column {name: "L_RETURNFLAG"}
    string returnFlag;

    @sql:Column {name: "L_LINESTATUS"}
    string lineStatus;

    @sql:Column {name: "L_COMMENT"}
    string comment;
};
