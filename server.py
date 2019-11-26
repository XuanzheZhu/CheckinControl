#coding:utf-8
#import necessary package
import socket
import time
import sys
import threading
import ctypes
#import RPi.GPIO as GPIO
#define host ip: Rpi's IP
HOST_IP = "10.180.146.206" #"10.180.0.4"
HOST_PORT = 9876
print("Starting socket: TCP...")
#1.create socket object:socket=socket.socket(family,type)
socket_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#socket_tcp.close()
print("TCP server listen @ %s:%d!" %(HOST_IP, HOST_PORT) )
host_addr = (HOST_IP, HOST_PORT)
#2.bind socket to addr:socket.bind(address)
#Prevent socket.error: [Errno 98] Address already in use
socket_tcp.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
socket_tcp.bind(host_addr)
#3.listen connection request:socket.listen(backlog)
socket_tcp.listen(1)
#4.waite for client:connection,address=socket.accept()
socket_con, (client_ip, client_port) = socket_tcp.accept()
print("Connection accepted from %s." %client_ip)
socket_con.send(bytes("Welcome to RPi TCP server!", 'UTF-8'))
print("Receiving package...")

# status : 0->register, 1->checkin, 3->clear
status = -1
hashMap = {}

# input the original student list
studentList = open("studentList.csv", "r")
for line in studentList.readlines():
    if len(line) > 2:
        data = line.split(",")
        hashMap[data[0]] = data[1]
studentList.close()

message = ""

def inputMessage():
    global message
    while True:
        message = input()

input_thread = threading.Thread(target = inputMessage)
input_thread.daemon = True
input_thread.start()

transfer = ""

def register(studentID):
    global message
    while message == "":
        time.sleep(0.1)
    if status == 0:
        cardID = message
        message = ""
    else:
        return
    hashMap[cardID] = studentID
    studentList = open("studentList.csv", "a")
    studentList.write(cardID + "," + studentID + ",0" + "\n")
    studentList.close()
    socket_con.send(bytes(studentID + " has been registered", 'UTF-8'))

def checkin():
    global message
    while True:
        if status == 1:
            while message == "":
                time.sleep(0.1)
            if status == 1:
                cardID = message
                message = ""
            else:
                continue
            if cardID not in hashMap:
                continue
            temp = ""
            studentList = open("studentList.csv", "r+")
            for line in studentList.readlines():
                if (line.find(cardID) == 0):
                    line = cardID + "," + hashMap[cardID] + ",1" + "\n"
                temp += line
            studentList.close()
            studentList = open("studentList.csv", "r+")
            studentList.writelines(temp)
            studentList.close()
            socket_con.send(bytes(hashMap[cardID] + " has been checked in", 'UTF-8'))

def clear():
    studentList = open("studentList.csv", "w")
    for cardID in hashMap:
        studentList.write(cardID + "," + hashMap[cardID] + ",0" + "\n")
    studentList.close()

class thread_with_exception(threading.Thread): 
    def __init__(self, name): 
        threading.Thread.__init__(self) 
        self.name = name 
              
    def run(self): 
  
        # target function of the thread class 
        try: 
            while True: 
                checkin()
        finally: 
            print('ended') 
           
    def get_id(self): 
  
        # returns id of the respective thread 
        if hasattr(self, '_thread_id'): 
            return self._thread_id 
        for id, thread in threading._active.items(): 
            if thread is self: 
                return id
   
    def raise_exception(self): 
        thread_id = self.get_id() 
        res = ctypes.pythonapi.PyThreadState_SetAsyncExc(thread_id, 
              ctypes.py_object(SystemExit)) 
        if res > 1: 
            ctypes.pythonapi.PyThreadState_SetAsyncExc(thread_id, 0) 
            print('Exception raise failure')

while True:
    try:
        command=socket_con.recv(512)
        if len(command) > 0:
            command = command.decode("UTF-8")
            print("Received: " + command)
            if command == "register":
                if status == 1:
                    checkin_thread.raise_exception()
                status = 0
                socket_con.send(bytes("Switched to " + command + " mode", 'UTF-8'))
            elif command == "checkin":
                status = 1
                checkin_thread = thread_with_exception('Thread 1')
                checkin_thread.start()
                socket_con.send(bytes("Switched to " + command + " mode", 'UTF-8'))
            elif command == "clearCheckin":
                clear()
            else:
                if status == 0:
                    register(command)
            time.sleep(1)
            continue
    except Exception:
            socket_tcp.close()
            sys.exit(1)
