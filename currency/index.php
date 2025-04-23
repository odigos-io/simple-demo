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

$app->get('/usd-ils', function (Request $request, Response $response) use ($logger) {
  $params = $request->getQueryParams();
  $logger->info("Got request for USD to ILS conversion.", ['params' => $params]);

  $result = (new Dice($logger))->rollOnce();
  $logger->info("Got value of 1 USD in ILS.", ['result' => $result]);

  $response = $response->withHeader('Content-Type', 'application/json');
  $response->getBody()->write(json_encode($result));
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
