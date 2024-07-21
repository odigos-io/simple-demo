const assert = require("assert");
const util = require("util");
const { trace } = require("@opentelemetry/api");

const express = require("express");

const PORT = parseInt(process.env.PORT || "8080");
const app = express();
const axios = require("axios");

const { MEMBERSHIP_SERVICE_HOST } = process.env;

assert.equal(
  typeof MEMBERSHIP_SERVICE_HOST,
  "string",
  `Expexted 'MEMBERSHIP_SERVICE_HOST' to be set. Got: ${util.format(
    MEMBERSHIP_SERVICE_HOST
  )}`
);

function getRandomNumber(min, max) {
  return Math.floor(Math.random() * (max - min) + min);
}

app.get("/healthz", (req, res) => {
  res.status(200).send("Coupon service is up and running!");
});

app.get("/coupons", (req, res) => {
  console.log("Coupon request received!");

  const appTracer = trace.getTracer("coupon");
  const newCouponNumber = appTracer.startActiveSpan(
    "generate new coupon",
    (span) => {
      try {
        return getRandomNumber(1, 25);
      } finally {
        span.end();
      }
    }
  );

  // Fetch from membership api
  axios
    .get(`http://${MEMBERSHIP_SERVICE_HOST}/isMember`)
    .then(function (response) {
      console.log("Got response from membership service!", response.data);
      res.json({
        coupon: newCouponNumber,
        isMember: response.data.isMember,
      });
    })
    .catch(function (error) {
      console.log(error);
    });
});

app.post("/apply-coupon", (req, res) => {
  console.log("Applying coupon!");

  const appTracer = trace.getTracer("coupon");
  const newCouponNumber = appTracer.startActiveSpan(
    "generate new coupon",
    (span) => {
      try {
        return getRandomNumber(1, 25);
      } finally {
        span.end();
      }
    }
  );

  // Fetch from membership api
  axios
    .get(`http://${MEMBERSHIP_SERVICE_HOST}/isMember`)
    .then(function (response) {
      console.log("Got response from membership service!", response.data);
      res.json({
        coupon: newCouponNumber,
        isMember: response.data.isMember,
      });
    })
    .catch(function (error) {
      console.log(error);
    });
});

const server = app.listen(PORT, () => {
  console.log(`Listening for requests on port ${PORT}`);
});

// Add signal handler to gracefully shutdown the server
process.on("SIGTERM", () => {
  console.log("Received SIGTERM. Shutting down server.");
  server.close(() => {
    console.log("Server closed.");
  });
});
