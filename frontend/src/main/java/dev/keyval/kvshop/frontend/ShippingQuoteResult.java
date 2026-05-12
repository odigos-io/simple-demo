package dev.keyval.kvshop.frontend;

import com.fasterxml.jackson.annotation.JsonProperty;

public class ShippingQuoteResult {
    @JsonProperty("productId")
    private int productId;

    @JsonProperty("shippingCents")
    private int shippingCents;

    @JsonProperty("carrier")
    private String carrier;

    public ShippingQuoteResult() {}

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public int getShippingCents() {
        return shippingCents;
    }

    public void setShippingCents(int shippingCents) {
        this.shippingCents = shippingCents;
    }

    public String getCarrier() {
        return carrier;
    }

    public void setCarrier(String carrier) {
        this.carrier = carrier;
    }
}
