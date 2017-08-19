//
//  HTMLSAXParserHandlers.h
//  HTMLSAXParser
//
//  Created by Raymond Mccrae on 31/07/2017.
//  Copyright © 2017 Raymond McCrae.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <libxml/SAX2.h>
#import <libxml/HTMLparser.h>

#ifndef HTMLParserHandlers_h
#define HTMLParserHandlers_h

typedef void(*HTMLParserWrappedErrorSAXFunc)(void *ctx, const char *msg);
typedef void(*HTMLParserWrappedWarningSAXFunc)(void *ctx, const char *msg);

extern HTMLParserWrappedErrorSAXFunc htmlparser_global_error_sax_func;
extern HTMLParserWrappedWarningSAXFunc htmlparser_global_warning_sax_func;

void htmlparser_set_global_error_handler(void *sax_handler);
void htmlparser_set_global_warning_handler(void *sax_handler);

#endif /* HTMLParserHandlers_h */
