import TelegramBot from 'node-telegram-bot-api';
import fetch from 'node-fetch';
import dotenv from 'dotenv';

dotenv.config();

const TELEGRAM_BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN || '';
const API_URL = process.env.API_URL || 'https://187.127.45.32:3000';
const ADMIN_IDS = (process.env.ADMIN_IDS || '').split(',').map(id => parseInt(id, 10)).filter(id => !isNaN(id));

const bot = new TelegramBot(TELEGRAM_BOT_TOKEN, { polling: true });

console.log('✓ Telegram Bot started');
console.log(`✓ Admin IDs: ${ADMIN_IDS.join(', ')}`);
console.log(`✓ API URL: ${API_URL}`);

// Verificar se o usuário é admin
function isAdmin(userId: number): boolean {
  return ADMIN_IDS.includes(userId);
}

// Gerar uma chave de licença
bot.onText(/\/gerar\s(\d+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from!.id;
  const days = parseInt(match![1], 10);

  if (!isAdmin(userId)) {
    bot.sendMessage(chatId, '❌ Você não tem permissão para usar este comando.');
    return;
  }

  if (![1, 3, 7, 15, 30].includes(days)) {
    bot.sendMessage(chatId, '❌ Duração inválida. Use: /gerar [1|3|7|15|30]');
    return;
  }

  try {
    const response = await fetch(`${API_URL}/api/license/generate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ durationDays: days }),
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    const data: any = await response.json();
    const key = data.key;

    bot.sendMessage(
      chatId,
      `✅ Chave gerada com sucesso!\n\n🔑 Chave: <code>${key}</code>\n⏱️ Duração: ${days} dias\n\nA contagem inicia quando a chave for ativada no dispositivo.`,
      { parse_mode: 'HTML' }
    );
  } catch (error) {
    console.error('Error generating license:', error);
    bot.sendMessage(chatId, '❌ Erro ao gerar chave. Tente novamente.');
  }
});

// Obter informações de uma chave
bot.onText(/\/info\s(.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from!.id;
  const key = match![1].toUpperCase();

  if (!isAdmin(userId)) {
    bot.sendMessage(chatId, '❌ Você não tem permissão para usar este comando.');
    return;
  }

  try {
    const response = await fetch(`${API_URL}/api/license/info`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key }),
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    const license: any = await response.json();

    if (!license) {
      bot.sendMessage(chatId, '❌ Chave não encontrada.');
      return;
    }

    const info = `
📋 Informações da Licença

🔑 Chave: <code>${key}</code>
📊 Status: ${license.status}
⏱️ Duração: ${license.durationDays} dias
📅 Criada em: ${new Date(license.createdAt).toLocaleString('pt-BR')}
${license.activatedAt ? `✅ Ativada em: ${new Date(license.activatedAt).toLocaleString('pt-BR')}` : '⏳ Não ativada'}
${license.expiresAt ? `⏰ Expira em: ${new Date(license.expiresAt).toLocaleString('pt-BR')}` : ''}
${license.deviceHash ? `📱 Dispositivo: ${license.deviceHash.substring(0, 16)}...` : ''}
${license.lastCheckedAt ? `🔍 Última verificação: ${new Date(license.lastCheckedAt).toLocaleString('pt-BR')}` : ''}
    `;

    bot.sendMessage(chatId, info, { parse_mode: 'HTML' });
  } catch (error) {
    console.error('Error getting license info:', error);
    bot.sendMessage(chatId, '❌ Erro ao obter informações. Tente novamente.');
  }
});

// Revogar uma chave
bot.onText(/\/revogar\s(.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from!.id;
  const key = match![1].toUpperCase();

  if (!isAdmin(userId)) {
    bot.sendMessage(chatId, '❌ Você não tem permissão para usar este comando.');
    return;
  }

  try {
    const response = await fetch(`${API_URL}/api/license/revoke`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key }),
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    const result: any = await response.json();

    if (result.success) {
      bot.sendMessage(chatId, `✅ Chave <code>${key}</code> foi revogada com sucesso.`, { parse_mode: 'HTML' });
    } else {
      bot.sendMessage(chatId, '❌ Chave não encontrada.');
    }
  } catch (error) {
    console.error('Error revoking license:', error);
    bot.sendMessage(chatId, '❌ Erro ao revogar chave. Tente novamente.');
  }
});

// Reativar uma chave
bot.onText(/\/reativar\s(.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from!.id;
  const key = match![1].toUpperCase();

  if (!isAdmin(userId)) {
    bot.sendMessage(chatId, '❌ Você não tem permissão para usar este comando.');
    return;
  }

  try {
    const response = await fetch(`${API_URL}/api/license/reactivate`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key }),
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    const result: any = await response.json();

    if (result.success) {
      bot.sendMessage(chatId, `✅ Chave <code>${key}</code> foi reativada com sucesso.`, { parse_mode: 'HTML' });
    } else {
      bot.sendMessage(chatId, '❌ Chave não encontrada.');
    }
  } catch (error) {
    console.error('Error reactivating license:', error);
    bot.sendMessage(chatId, '❌ Erro ao reativar chave. Tente novamente.');
  }
});

// Deletar uma chave
bot.onText(/\/deletar\s(.+)/, async (msg, match) => {
  const chatId = msg.chat.id;
  const userId = msg.from!.id;
  const key = match![1].toUpperCase();

  if (!isAdmin(userId)) {
    bot.sendMessage(chatId, '❌ Você não tem permissão para usar este comando.');
    return;
  }

  try {
    const response = await fetch(`${API_URL}/api/license/delete`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ key }),
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    const result: any = await response.json();

    if (result.success) {
      bot.sendMessage(chatId, `✅ Chave <code>${key}</code> foi deletada com sucesso.`, { parse_mode: 'HTML' });
    } else {
      bot.sendMessage(chatId, '❌ Chave não encontrada.');
    }
  } catch (error) {
    console.error('Error deleting license:', error);
    bot.sendMessage(chatId, '❌ Erro ao deletar chave. Tente novamente.');
  }
});

// Listar todas as chaves
bot.onText(/\/listar/, async (msg) => {
  const chatId = msg.chat.id;
  const userId = msg.from!.id;

  if (!isAdmin(userId)) {
    bot.sendMessage(chatId, '❌ Você não tem permissão para usar este comando.');
    return;
  }

  try {
    const response = await fetch(`${API_URL}/api/license/list`, {
      method: 'GET',
      headers: { 'Content-Type': 'application/json' },
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    const licenses: any[] = await response.json();

    if (licenses.length === 0) {
      bot.sendMessage(chatId, '📭 Nenhuma chave encontrada.');
      return;
    }

    let message = '📋 Lista de Licenças\n\n';
    licenses.slice(0, 10).forEach((license, index) => {
      message += `${index + 1}. Status: ${license.status} | Duração: ${license.durationDays}d | Criada: ${new Date(license.createdAt).toLocaleDateString('pt-BR')}\n`;
    });

    if (licenses.length > 10) {
      message += `\n... e mais ${licenses.length - 10} licenças`;
    }

    bot.sendMessage(chatId, message);
  } catch (error) {
    console.error('Error listing licenses:', error);
    bot.sendMessage(chatId, '❌ Erro ao listar chaves. Tente novamente.');
  }
});

// Comando de ajuda
bot.onText(/\/help|\/start/, (msg) => {
  const chatId = msg.chat.id;
  const userId = msg.from!.id;

  if (!isAdmin(userId)) {
    bot.sendMessage(chatId, '❌ Você não tem permissão para usar este bot.');
    return;
  }

  const help = `
🔐 Sistema de Licenciamento - Comandos

📌 Gerar Licença:
/gerar [1|3|7|15|30] - Gera uma chave com duração em dias

📌 Gerenciar Licenças:
/info CHAVE - Exibe informações da chave
/revogar CHAVE - Revoga uma chave
/reativar CHAVE - Reativa uma chave
/deletar CHAVE - Deleta uma chave
/listar - Lista todas as chaves

📌 Outros:
/help - Mostra esta mensagem
  `;

  bot.sendMessage(chatId, help);
});

// Error handling
bot.on('polling_error', (error) => {
  console.error('Polling error:', error);
});

export default bot;
