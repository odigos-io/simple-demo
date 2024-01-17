# Simple Demo Applications
This repository contains the code for the Simple Demo Applications.
This application is a simple e-commerce application that allows users to purchase items from a catalog.
This application is used to demonstrate the capabilities of Odigos.

## Architecture

Simple Demo contains the following services:

| Service | Language | Version |
| --- | --- | --- |
| Frontend | Java | 17 (Eclipse Temurin) |
| Inventory | Python | 3.11 |
| Pricing | Java | 8 (Eclipse Temurin) |
| Membership | Go | 1.21 |
| Coupon | JavaScript | NodeJS 18.3.0 |

## Running locally

To build the project and run it locally on a Kind cluster, run the following command:

```bash
make build-images load-to-kind deploy
```