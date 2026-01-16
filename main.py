‎import discord
‎from discord import app_commands
‎import asyncio
‎from collections import deque
‎
‎TOKEN = ""
‎
‎INTENTS = discord.Intents.default()
‎STEALTH_LINK = "https://discord.gg/FvWQ9AMMPD"
‎SPAM_DELAY = 0.3
‎
‎class Scarware(discord.Client):
‎    def __init__(self):
‎        super().__init__(intents=INTENTS)
‎        self.tree = app_commands.CommandTree(self)
‎        self.queue = deque()
‎
‎    async def setup_hook(self):
‎        await self.tree.sync()
‎        self.loop.create_task(self.worker())
‎        print("scarware online")
‎
‎    async def worker(self):
‎        while True:
‎            if self.queue:
‎                channel, msg = self.queue.popleft()
‎                try:
‎                    await channel.send(msg)
‎                    await asyncio.sleep(SPAM_DELAY)
‎                except:
‎                    pass
‎            else:
‎                await asyncio.sleep(0.1)
‎
‎client = Scarware()
‎
‎
‎@client.tree.command(name="test", guild_only=True)
‎async def test(interaction: discord.Interaction):
‎    await interaction.response.send_message(
‎        "it's up nga now do ur job",
‎        ephemeral=True
‎    )
‎
‎@client.tree.command(name="say", guild_only=True)
‎@app_commands.describe(text="Text to say once")
‎async def say(interaction: discord.Interaction, text: str):
‎    await interaction.response.send_message(STEALTH_LINK, ephemeral=True)
‎    await interaction.channel.send(text)
‎
‎@client.tree.command(name="spam", guild_only=True)
‎@app_commands.describe(text="Text to spam 5 times")
‎async def spam(interaction: discord.Interaction, text: str):
‎    await interaction.response.send_message(STEALTH_LINK, ephemeral=True)
‎    for _ in range(5):
‎        client.queue.append((interaction.channel, text))
‎
‎@client.tree.command(name="raid", guild_only=True)
‎@app_commands.describe(text="# SCARWARE OWNS YOU https://discord.gg/k2wDc4ep5W ↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯↯https://cdn.discordapp.com/attachments/1459269162378596591/1460983237483565209/lv_0_20260114145738.gif?ex=6968e62b&is=696794ab&hm=e03345f24e97c848f55c85f2fdedfbbba4ea8b2de7f0ee06bd705edd5853cd87& https://cdn.discordapp.com/attachments/1446810783714512907/1460972235442491477/Lrgqq2ugfDA1PscOGT.gif #")
‎async def diar(interaction: discord.Interaction, text: str):
‎    await interaction.response.send_message(STEALTH_LINK, ephemeral=True)
‎    for _ in range(5):
‎        client.queue.append((interaction.channel, text))
‎
‎client.run()
