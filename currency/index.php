<?php

use Psr\Http\Message\ResponseInterface as Response;
use Psr\Http\Message\ServerRequestInterface as Request;
use Slim\Factory\AppFactory;
use Monolog\Logger;
use Monolog\Level;
use Monolog\Handler\StreamHandler;

require __DIR__ . '/vendor/autoload.php';
require('dice.php');

$logger = new Logger('currency-server');
$logger->pushHandler(new StreamHandler('php://stdout', Level::Info));

$app = AppFactory::create();

$app->addErrorMiddleware(true, true, true)->setDefaultErrorHandler(function (
  Request $request,
  Throwable $exception,
  bool $displayErrorDetails
) use ($app) {
  $response = $app->getResponseFactory()->createResponse();
  $response->withHeader('Content-Type', 'application/json')->withStatus(500);
  $response->getBody()->write(json_encode(['error' => $exception->getMessage()]));
  return $response;
});

$app->get('/rate/{currencyPair}', function (
  Request $request,
  Response $response,
  array $args
) use ($logger) {
  $currencyPair = $args['currencyPair'];
  $logger->info("Got request...", ['currencyPair' => $currencyPair]);

  $conversionRate = (new Dice($logger))->rollOnce();
  $logger->info("Got conversion rate for pair:", ['currencyPair' => $currencyPair, 'conversionRate' => $conversionRate]);

  $response = $response->withHeader('Content-Type', 'application/json');
  $response->getBody()->write(json_encode(['conversionRate' => $conversionRate]));
  return $response;
});

// $app->get('/rolldice', function (Request $request, Response $response) use ($logger, $dice) {
//   $params = $request->getQueryParams();

//   if (isset($params['rolls'])) {
//     $result = $dice->roll($params['rolls']);
//   } else {
//     $result = $dice->rollOnce();
//   }

//   if (isset($params['player'])) {
//     $logger->info("A player is rolling the dice.", ['player' => $params['player'], 'result' => $result]);
//   } else {
//     $logger->info("Anonymous player is rolling the dice.", ['result' => $result]);
//   }

//   $response = $response->withHeader('Content-Type', 'application/json');
//   $response->getBody()->write(json_encode($result));
//   return $response;
// });

$app->run();
