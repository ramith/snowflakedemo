import ballerina/http;
import ballerina/sql;
import ballerinax/snowflake; // Get the Snowflake connector
import ballerinax/snowflake.driver as _;
import ballerina/log;

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

configurable string account_identifier = ?; //e.g "uz******.east-us-2.azure";
configurable string user = ?;
configurable string password = ?;

snowflake:Options options = {
    requestGeneratedKeys: snowflake:NONE // This should be specified
};

snowflake:Client snowflakeClient = check new (account_identifier, user, password, options);

# A example service demonstrating how to connect to snowflake database.
# bound to port `9090`
service / on new http:Listener(9090) {

    # This API resource uses a query (and dataset) privided with Snowflake samples.
    # The tutorial can be found at: https://docs.snowflake.com/en/user-guide/sample-data-tpch.html
    # + shippedDate - shipped date of line items
    # + numberOfDays - number of days include.
    # + return - pricing summary or error
    resource function get pricingSummary(string shippedDate = "1998-12-01", int numberOfDays = 90) returns PricingSummary[]|error {
        sql:ParameterizedQuery sqlQuery = `SELECT l_returnflag, l_linestatus, 
                                                  sum(l_quantity) as sum_qty, 
                                                  sum(l_extendedprice) as sum_base_price, 
                                                  sum(l_extendedprice * (1-l_discount)) as sum_disc_price, 
                                                  sum(l_extendedprice * (1-l_discount) * (1+l_tax)) as sum_charge, 
                                                  avg(l_quantity) as avg_qty, 
                                                  avg(l_extendedprice) as avg_price, 
                                                  avg(l_discount) as avg_disc, 
                                                  count(*) as count_order 
                                            FROM snowflake_sample_data.tpch_sf1.lineitem 
                                            WHERE l_shipdate <= dateadd(day, - ${numberOfDays}, to_date(${shippedDate})) 
                                            GROUP BY l_returnflag, l_linestatus 
                                            ORDER BY l_returnflag, l_linestatus`;

        stream<PricingSummary, error?> results = snowflakeClient->query(sqlQuery);

        PricingSummary[] report = [];

        check from PricingSummary entry in results
            do {
                report.push(entry);
            };

        return report;
    }

    # returns all line items of a order given the order id
    # + orderId - order id ( e.g. 4200001) 
    # + return - line items or an error
    resource function get orders/[int orderId]/lineitems() returns LineItem[]|error {
        sql:ParameterizedQuery sqlQuery = `SELECT 
                                                L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY, 
                                                L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS, L_SHIPDATE, 
                                                L_COMMITDATE, L_RECEIPTDATE, L_SHIPINSTRUCT, L_SHIPMODE, 
                                                L_COMMENT 
                                            FROM 
                                                SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM LI WHERE LI.L_ORDERKEY = ${orderId}`;
        stream<LineItem, error?> results = snowflakeClient->query(sqlQuery);
        LineItem[] lineItems = [];
        check from LineItem entry in results
            do {
                lineItems.push(entry);
            };

        return lineItems;
    }

    # returns an line item given the order id and line number
    # + orderId - order id ( e.g. 4200001) 
    # + lineNumber - line number ( e.g. 1)
    # + return - line item or an error
    resource function get orders/[int orderId]/lineitems/[int lineNumber](http:Caller caller) returns error? {
        sql:ParameterizedQuery sqlQuery = `SELECT 
                                                L_ORDERKEY, L_PARTKEY, L_SUPPKEY, L_LINENUMBER, L_QUANTITY, 
                                                L_EXTENDEDPRICE, L_DISCOUNT, L_TAX, L_RETURNFLAG, L_LINESTATUS, L_SHIPDATE, 
                                                L_COMMITDATE, L_RECEIPTDATE, L_SHIPINSTRUCT, L_SHIPMODE, 
                                                L_COMMENT 
                                            FROM 
                                                SNOWFLAKE_SAMPLE_DATA.TPCH_SF1.LINEITEM LI 
                                            WHERE LI.L_ORDERKEY = ${orderId} AND LI.L_LINENUMBER = ${lineNumber}`;

        LineItem|sql:Error lineItem = snowflakeClient->queryRow(sqlQuery);
        if lineItem is sql:NoRowsError {
            log:printWarn("unable to find the line item", orderId = orderId, lineNumber = lineNumber);
            _ = check caller->respond(http:NOT_FOUND);
        } else {
            _ = check caller->respond(lineItem);
        }
    }
}