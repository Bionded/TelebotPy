# -*- coding: utf-8 -*-
import config
import telebot
import os
import subprocess
from telebot import types

bot = telebot.TeleBot(config.token)
serverdir = "./Servers/"
@bot.message_handler(commands=['getchatid'])
def get_chat_id(message):
    bot.send_message(message.chat.id,message.chat.id)

@bot.message_handler(commands=['start'])
def get_chat_id(message):
    if str(message.chat.id) in str(config.chatid):
        bot.send_message(message.chat.id, "Воспоьзуйтесь /servers или /getchatid")
    else:
        bot.send_message(message.chat.id, "Для использования бота внесите "+str(message.chat.id)+" в разрешенный пул")

@bot.message_handler(commands=['servers'])
def get_servers(message):
    if str(message.chat.id) in str(config.chatid):
        keyboard = types.InlineKeyboardMarkup(row_width=2)
        for x in os.listdir(serverdir):
            if os.path.isdir(serverdir + x):
                callback_button = types.InlineKeyboardButton(text=x, callback_data=x)
                keyboard.add(callback_button)

        bot.send_message(message.chat.id, "Выбери сервер:", reply_markup=keyboard)
    else:
        bot.send_message(message.chat.id, "Некорректный доступ! Внесите "+str(message.chat.id)+" в разрешенный пул")

@bot.callback_query_handler(func=lambda call: True)
def callback_inline(call):
    if str(call.message.chat.id) in str(config.chatid):
        if os.path.isdir(serverdir + call.data):
            keyboard = types.InlineKeyboardMarkup(row_width=3)
            for x in os.listdir(serverdir + "/" + call.data):
                callback_button = types.InlineKeyboardButton(text=x, callback_data=call.data + "/" + x)
                keyboard.add(callback_button)
            bot.send_message(call.message.chat.id, "Что запустить?", reply_markup=keyboard)
        else:
            subprocess.call(serverdir + "/" + call.data, shell=True)
            bot.send_message(call.message.chat.id, "Скрипт " + str(call.data) + " Успешно запущен")
    else:
        bot.send_message(message.chat.id, "Некорректный доступ! Внесите "+str(message.chat.id)+" в разрешенный пул")


@bot.message_handler(content_types=["text"])
def repeat_all_messages(message): # Название функции не играет никакой роли, в принципе
    if str(message.chat.id) in str(config.chatid):
        bot.send_message(message.chat.id, "Неизвестная команда! Воспоьзуйтесь /servers или /getchatid")
    else:
        bot.send_message(message.chat.id, "Некорректный доступ и неизвестная команда! Внесите "+str(message.chat.id)+" в разрешенный пул")

if __name__ == '__main__':
     bot.polling(none_stop=True)
