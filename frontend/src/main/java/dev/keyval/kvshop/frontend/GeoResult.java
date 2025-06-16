package dev.keyval.kvshop.frontend;

import com.fasterxml.jackson.annotation.JsonProperty;

public class GeoResult {
    @JsonProperty("ticker")
    private String ticker;

    @JsonProperty("origin")
    private String origin;

    @JsonProperty("flag")
    private String flag;

    public GeoResult() {
        // Default constructor for deserialization
    }

    public GeoResult(String ticker, String origin, String flag) {
        // Constructor for initialization
        this.ticker = ticker;
        this.origin = origin;
        this.flag = flag;
    }

    public void setTicker(String ticker) {
        this.ticker = ticker;
    }

    public void setOrigin(String origin) {
        this.origin = origin;
    }

    public void setFlag(String flag) {
        this.flag = flag;
    }

    public String getTicker() {
        return this.ticker;
    }

    public String getOrigin() {
        return this.origin;
    }

    public String getFlag() {
        return this.flag;
    }
}
