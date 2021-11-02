#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, sys, getopt, ast, re
import mistune
import logging

logging.basicConfig(format='%(levelname)s: %(message)s', level=logging.DEBUG)
_NAME = os.path.basename(sys.argv[0])

def process(input_file, output_file):
    logging.debug('%s -> %s', input_file, output_file)
    logging.debug('Reading %s', input_file)

    with open(input_file, mode='r', encoding="utf-8") as source:
         text = source.read()

    logging.debug('Processing %s', input_file)

    markdown = mistune.create_markdown(renderer='ast')
    parsed = markdown(text)
    logging.debug('%s', parsed)

    content = []

    for child in parsed:
        # logging.debug('%s', child)
        if child['type'] == 'heading':
            content.append(child['children'][0]['text'] + '\n')
        elif child['type'] == 'list':
            for item in child['children']:
                if item['type'] == 'list_item':
                    text = item['children'][0]['children'][0]['text']
                    logging.debug('list_item -> %s', text)
                    content.append('* ' + text + '\n')

    content.append('\n')

    logging.debug('Processing %s', output_file)

    inserting, index = True, 0
    with open(output_file, mode='r', encoding="utf-8") as current:
        for line in current:
            # logging.debug('%s', line)
            if inserting:
                content.insert(index, line)
            else:
                content.append(line)

            if re.search(r'^AddOn\.Changelog.*', line):
                inserting = False

            index = index + 1

    logging.debug('Writing %s', output_file)
    with open(output_file, mode='w', encoding="utf-8") as append:
        append.writelines(content)

def main(argv):
    input_file = None
    output_file = None

    try:
        opts, args = getopt.getopt(argv,"i:o:")
    except getopt.GetoptError:
        print(_NAME + ' -i <inputfile> -o <outputfile>')
        sys.exit(2)

    for opt, arg in opts:
        if opt in ("-i"):
             input_file = arg
        elif opt in ("-o"):
            output_file = arg

    if not input_file or not output_file:
        print(_NAME + ' -i <inputfile> -o <outputfile>')
        sys.exit(2)

    process(input_file, output_file)

if __name__ == "__main__":
   main(sys.argv[1:])