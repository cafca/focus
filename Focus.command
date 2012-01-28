#!/usr/bin/env python
# encoding: utf-8
# file: focus.command
"""
focus.command

Created by Vincent Ahrend on 2012-01-15.
Copyright (c) 2012 Vincent Ahrend. All rights reserved.
"""

import sys

import os
import time, random
import json
from math import sqrt
from datetime import datetime, timedelta
import dateutil.parser

VERSION = '2'
DATA_FILE = './focus.data'

class Data():
    def __init__(self, username=None):
        try:
            with open(DATA_FILE, 'r+') as f: 
                self.data = json.load(f) 
        except IOError:
            # file doesn't exist
            self.data = self.init_data_file()
        except ValueError:
            print "Data file seems corrupted. Please check manually."
            quit()
        
        if username=="": username = 'default'
        
        self.current_user = username or self.data['current_user']
        
    def init_data_file(self):
        data = dict()
        data['records'] = dict()
        data['records']['default'] = list()
            
        with open(DATA_FILE, 'w') as f:
            f.write(json.dumps(data))
            
        return data
        
    def new_record(self, samples):
        temp = dict()
        temp['version'] = VERSION
        temp['samples'] = samples
        temp['time'] = datetime.now().isoformat()
        mean, sd = stat(samples)
        temp['mean'] = mean
        temp['sd'] = sd
        
        self.data['records'][self.current_user].append(temp)
        self.save()
        
    def save(self):
        try:
            with open(DATA_FILE, 'w') as f:
                f.write(json.dumps(self.data, sort_keys=True, indent=4))
        except:
            print "Unable to save data. Do I have write access?"
            
    def last_record(self):
        return self.data['records'][self.current_user][-1]
        
    def print_records(self):
        total = len(self.data['records'][self.current_user])
        print "%s records found.\n" % total
        i = total-9
        for r in self.data['records'][self.current_user][-10:]:
            t = dateutil.parser.parse(r['time'])
            print "{0:2.0f} {1:%Y-%m-%d %H:%M:%S}\t{2:.0f} ms\t{3:.0f} ms".format(i, t, r['mean'], r['sd'])
            i += 1
        print
        
    def tired(self):
        # get sorted mean reaction times
        samples = sorted([r['mean'] for r in self.data['records'][self.current_user]])
        
        # first and third quartile
        q1 = samples[int(len(samples)/4)]
        q3 = samples[int(2*len(samples)/4)]
        
        return 1-((self.last_record()['mean']-q1) / (q3-q1))
        
        
        

def clear():
    os.system('clear')
    
def test():
    # wait 1 < n < 5 seconds
    time.sleep(2 + (random.random()*8))
    print "--- NOW! ---"
    a = time.time()
    rt = 0
    while rt < 80:
        temp = raw_input()
        b = time.time()
        rt = (b - a) * 1000
    return rt

def stat(t):
    mean = sum(t) / len(t)
    sd = sqrt(sum([pow((a-mean),2) for a in t])/len(t))
    return (mean, sd)
    
def main():
    print "HOWTO: Press ENTER when prompted. 2-10 second delay between prompts. 2 minutes total."
    
    username = raw_input("ENTER NEW USERNAME OR 'ENTER' FOR DEFAULT USER")
    dat = Data(username)
    clear()
    
    dat.print_records()
    raw_input("PRESS ENTER TO START")
    
    clear()
    
    for i in xrange(3):
        print int(test()), "ms"
    
    t = []
    stats = []
    start = time.time()
    
    while (time.time()-start)<120:
        t.append(test())
        clear()
        print "%02.0f:%02.0f" % divmod(120-(time.time()-start), 60), "left"
    
    dat.new_record(t)
    clear()
    
    print "-"*15, 'PREVIOUS MEASUREMENTS'
    dat.print_records()
    
    print "-"*15, 'CURRENT MEASUREMENT'
    for i in xrange(len(t)):
        print (1+i),int(t[i]),"ms"
    print
    print 'MEAN',int(dat.last_record()['mean']),"ms"  
    print 'SD  ',int(dat.last_record()['sd']),"ms"
    
    print "-"*15, 'RESULT'
    print "Your focus is at {:.2%}".format(dat.tired())
    
    


if __name__ == '__main__':
    main()

