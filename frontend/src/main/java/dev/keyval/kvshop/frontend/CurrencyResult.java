package dev.keyval.kvshop.frontend;

import com.fasterxml.jackson.annotation.JsonProperty;

public class CurrencyResult {
    @JsonProperty("conversionRate")
    private int conversionRate;

    @JsonProperty("convertedString")
    private String convertedString;

    public CurrencyResult() {
        // Default constructor for deserialization
    }

    public CurrencyResult(int conversionRate, String convertedString) {
        // Constructor for initialization
        this.conversionRate = conversionRate;
        this.convertedString = convertedString;
    }

    public void setConversionRate(int conversionRate) {
        this.conversionRate = conversionRate;
    }

    public void setConvertedString(String convertedString) {
        this.convertedString = convertedString;
    }

    public int getConversionRate() {
        return conversionRate;
    }

    public String getConvertedString() {
        return convertedString;
    }
}
