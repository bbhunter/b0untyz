'use strict';

var express = require('express'),
    exphbs  = require('./express-handlebars/'); // "express-handlebars"

var domain_name = process.argv[2];

var app = express();
var csv = require('csv'); 

var path_by_name = "../workspace/" + domain_name +  "/subdomains.by.name.process";
var path_by_address = "../workspace/" + domain_name +  "/subdomains.by.ip.process";

app.engine('handlebars', exphbs({defaultLayout: 'main'}));
app.set('view engine', 'handlebars');

var subdomains_by_name = [];
var subdomains_by_address = [];

function subdomains_name(name, type, addresses) {
    return {record_name: name, record_type: type, record_addresses: addresses} 
};

function subdomains_address(address, ptr, sdomains) {
    return {record_network: address, record_ptr: ptr, record_sdomains : sdomains};
};

csv().from.path(path_by_name).to.array(function (data) {
    for (var index = 0; index < data.length; index++) {
        subdomains_by_name.push(subdomains_name(...data[index]));
    }
});
csv().from.path(path_by_address).to.array(function (data) {
    for (var index = 0; index < data.length; index++) {
        subdomains_by_address.push(subdomains_address(...data[index]));
    }

});

app.get('/', function (req, res) {
    res.render('home', {
    show_subdomains_by_name: subdomains_by_name,
    show_subdomains_by_address: subdomains_by_address
    });
});



app.listen(3000, function () {
    console.log('express-handlebars example server listening on: 3000');
});
