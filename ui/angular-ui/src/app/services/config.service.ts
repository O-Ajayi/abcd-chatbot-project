import { Injectable } from '@angular/core';

export interface ChatConfig {
  botId: string;
  botAliasId: string;
  localeId: string;
  region: string;
}

@Injectable({
  providedIn: 'root'
})
export class ConfigService {
  private readonly CONFIG_KEY = 'chatbot_config';

  getConfig(): ChatConfig | null {
    const configStr = localStorage.getItem(this.CONFIG_KEY);
    if (configStr) {
      try {
        return JSON.parse(configStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  saveConfig(config: ChatConfig): void {
    localStorage.setItem(this.CONFIG_KEY, JSON.stringify(config));
  }

  clearConfig(): void {
    localStorage.removeItem(this.CONFIG_KEY);
  }
}

