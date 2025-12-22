import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ChatService } from './services/chat.service';
import { ConfigService } from './services/config.service';

interface Message {
  text: string;
  sender: 'user' | 'bot';
  timestamp: Date;
}

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  messages: Message[] = [];
  userMessage: string = '';
  isLoading: boolean = false;
  isConnected: boolean = false;
  connectionStatus: string = 'Not connected. Configure settings below.';

  // Configuration
  botId: string = '';
  botAliasId: string = '';
  localeId: string = 'en_US';
  region: string = 'us-east-1';
  sessionId: string = '';

  constructor(
    private chatService: ChatService,
    private configService: ConfigService
  ) {}

  ngOnInit() {
    this.loadConfiguration();
    this.addBotMessage('Hello! I\'m your chatbot assistant. Please configure your Bot ID and Alias ID to start chatting.');
  }

  loadConfiguration() {
    const config = this.configService.getConfig();
    if (config) {
      this.botId = config.botId || '';
      this.botAliasId = config.botAliasId || '';
      this.localeId = config.localeId || 'en_US';
      this.region = config.region || 'us-east-1';
      this.updateConnectionStatus();
    }
  }

  saveConfiguration() {
    this.configService.saveConfig({
      botId: this.botId,
      botAliasId: this.botAliasId,
      localeId: this.localeId,
      region: this.region
    });
    this.updateConnectionStatus();
    this.sessionId = this.generateSessionId();
  }

  updateConnectionStatus() {
    if (this.botId && this.botAliasId) {
      this.isConnected = true;
      this.connectionStatus = 'Connected and ready to chat!';
    } else {
      this.isConnected = false;
      this.connectionStatus = 'Not connected. Configure Bot ID and Alias ID above.';
    }
  }

  generateSessionId(): string {
    return 'session-' + Date.now() + '-' + Math.random().toString(36).substr(2, 9);
  }

  sendMessage() {
    if (!this.userMessage.trim() || !this.isConnected || this.isLoading) {
      return;
    }

    const messageText = this.userMessage.trim();
    this.addUserMessage(messageText);
    this.userMessage = '';
    this.isLoading = true;

    if (!this.sessionId) {
      this.sessionId = this.generateSessionId();
    }

    this.chatService.sendMessage({
      botId: this.botId,
      botAliasId: this.botAliasId,
      localeId: this.localeId,
      sessionId: this.sessionId,
      text: messageText,
      region: this.region
    }).subscribe({
      next: (response) => {
        this.isLoading = false;
        if (response.messages && response.messages.length > 0) {
          response.messages.forEach((msg: any) => {
            if (msg.content) {
              this.addBotMessage(msg.content);
            }
          });
        } else if (response.message) {
          this.addBotMessage(response.message);
        }
      },
      error: (error) => {
        this.isLoading = false;
        this.addBotMessage(`Error: ${error.error?.message || error.message || 'Failed to send message'}`);
        this.connectionStatus = 'Error connecting to chatbot. Please check your configuration.';
      }
    });
  }

  onKeyPress(event: KeyboardEvent) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      this.sendMessage();
    }
  }

  addUserMessage(text: string) {
    this.messages.push({
      text,
      sender: 'user',
      timestamp: new Date()
    });
    this.scrollToBottom();
  }

  addBotMessage(text: string) {
    this.messages.push({
      text,
      sender: 'bot',
      timestamp: new Date()
    });
    this.scrollToBottom();
  }

  scrollToBottom() {
    setTimeout(() => {
      const messagesContainer = document.querySelector('.messages');
      if (messagesContainer) {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
      }
    }, 100);
  }

  clearChat() {
    this.messages = [];
    this.sessionId = this.generateSessionId();
    this.addBotMessage('Chat cleared. How can I help you?');
  }
}

