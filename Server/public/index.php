<?php
date_default_timezone_set('Asia/Seoul');

use Psr\Http\Message\ServerRequestInterface as Request;
use Psr\Http\Message\ResponseInterface as Response;

require '../vendor/autoload.php';
require '../src/api.php';


$app = new Slim\App;

$app->post('/challenge', function (Request $request, Response $response) {
    $api = new API($request, $response);
    return $api->challengeFIDO();
});
$app->post('/login', function (Request $request, Response $response) {
    $api = new API($request, $response);
    return $api->login();
});
$app->post('/identity', function (Request $request, Response $response) {
    $api = new API($request, $response);
    return $api->identity();
});
$app->post('/users', function (Request $request, Response $response) {
    $api = new API($request, $response);
    return $api->createUser();
});
$app->delete('/users/{did}', function (Request $request, Response $response, array $args) {
    $api = new API($request, $response, $args);
    return $api->deleteUser();
});
$app->run();
?>
