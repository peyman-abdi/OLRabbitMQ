//
//  ViewController.m
//  OLRabbitMQ Example
/******************************************************************************
 *
 *  2015 (C) Copyright Open-RnD Sp. z o.o.
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *
 ******************************************************************************/

#import "ViewController.h"
#import <OLRabbitMQ/OLRabbitMQ.h>
#import <unistd.h>
              
@interface ViewController () <OLRabbitMQOperationDelegate> {
    NSString *vhost;
    NSString *login;
    NSString *password;
    
    NSString *address_ip;
    NSInteger port;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [OLRabbitMQManager setLogEnabled:YES];
    
    char hostname[256];
    gethostname(&hostname[0], 256);
    [self initRabbitSocketWithSSL:true];
}

- (void)initRabbitSocketWithSSL:(BOOL)ssl {
    address_ip = @"localhost";
    port = 5671;
    
    vhost = @"/";
    login = @"guest";
    password = @"guest";
    
    NSLog(@"create socket and try connect...");
    OLRabbitMQSocket *socket = [[OLRabbitMQSocket alloc] initWithIp:address_ip port:port];
    
    if (ssl) {
        NSString *path_cacert = [[NSBundle mainBundle] pathForResource:@"cacert" ofType:@"pem"];
        NSString *path_keypem = [[NSBundle mainBundle] pathForResource:@"rabbit-client.key" ofType:@"pem"];
        NSString *path_certpem = [[NSBundle mainBundle] pathForResource:@"rabbit-client.cert" ofType:@"pem"];
        OLRabbitMQError *error = [socket openWithSSLWithCacert:path_cacert keypem:path_keypem certpem:path_certpem];
        if (error) {
            return;
        }
    } else {
        [socket openWithoutSSL];
    }
    [socket loginVhost:vhost login:login password:password callback:^(BOOL ready, NSError *error) {
        
        if (ready) {
            OLRabbitMQExchange *exchange = [[OLRabbitMQExchange alloc] initWithSocket:socket];
            [exchange bindExchange:@"amq.direct" routingKey:@"test"];
            
            [exchange basicConsume];
            
            OLRabbitMQOperation *operation = [[OLRabbitMQOperation alloc] initWithSocket:socket];
            operation.delegate = self;
            [[NSOperationQueue new] addOperation:operation];
        }
        
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            NSLog(@"error: %@", error.localizedDescription);
        }
    }];
}



- (void)amqpResponse:(NSData *)data routingKey:(NSString *)routingKey {
    NSLog(@"routingKey: %@, data: %@", routingKey, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
