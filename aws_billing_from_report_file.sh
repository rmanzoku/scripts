#!/bin/bash

export AWS_SHARED_CREDENTIALS_FILE="$HOME/.aws/credentials"
export AWS_PROFILE=$1
BUCKET=${2}

AWS="aws"
Q='q'
TMPFILE="./tmp"

echo '"InvoiceID","PayerAccountId","LinkedAccountId","RecordType","RecordID","BillingPeriodStartDate","BillingPeriodEndDate","InvoiceDate","PayerAccountName","LinkedAccountName","TaxationAddress","PayerPONumber","ProductCode","ProductName","SellerOfRecord","UsageType","Operation","AvailabilityZone","RateId","ItemDescription","UsageStartDate","UsageEndDate","UsageQuantity","BlendedRate","CurrencyCode","CostBeforeTax","Credits","TaxAmount","TaxType","TotalCost"' > $TMPFILE

$AWS s3 ls "$BUCKET" \
    | grep "aws-cost-allocation-20" \
    | awk '{print $4}' \
    | xargs -I{} aws s3 cp "s3://$BUCKET/"{} - \
    | grep StatementTotal \
    | sed 's/\//-/g' >> $TMPFILE

SQL="SELECT
BillingPeriodStartDate,
BillingPeriodEndDate,
CurrencyCode,
CostBeforeTax,
Credits,
TaxAmount,
TotalCost,
30 * 1.08 * CostBeforeTax / (Cast(JulianDay(date(BillingPeriodEndDate)) - JulianDay(date(BillingPeriodStartDate)) AS integer)+1) AS StandardizedCost
FROM $TMPFILE"

$Q -d ',' -HO "$SQL"

rm $TMPFILE
