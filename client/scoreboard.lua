class "Scoreboard"

function Scoreboard:__init()
	self.open = false
	self.scrollOffset = 0
	self.playerData = {}

	Events:Subscribe("ModuleLoad", self, self.ModuleLoad)
	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
	Events:Subscribe("KeyDown", self, self.KeyDown)
	Events:Subscribe("KeyUp", self, self.KeyUp)
	Events:Subscribe("LocalPlayerInput", self, self.LocalPlayerInput)
	Events:Subscribe("MouseScroll", self, self.MouseScroll)
	Events:Subscribe("PlayerNetworkValueChange", self, self.PlayerNetworkValueChange)
	Events:Subscribe("Render", self, self.Render)
end

function Scoreboard:ModuleLoad()
	local players = {LocalPlayer}
	for player in Client:GetPlayers() do table.insert(players, player) end

	for k, player in pairs(players) do
		self.playerData[player:GetSteamId().id] = {
			name = player:GetName(),
			image = player:GetAvatar(),
			ping = player:GetValue("ping") or -1,
			color = player:GetColor()
		}
	end
end

function Scoreboard:PlayerQuit(args)
	self.playerData[args.player:GetSteamId().id] = nil
end

function Scoreboard:KeyDown(args)
	if args.key == VirtualKey.Tab and not self.open then
		self.open = true
		self:MouseScroll({delta = 0})

		Mouse:SetVisible(true)
		Chat:SetEnabled(false)
		Game:FireEvent("gui.hud.hide")
	end
end

function Scoreboard:KeyUp(args)
	if args.key == VirtualKey.Tab then
		self.open = false
		
		Mouse:SetVisible(false)
		Chat:SetEnabled(true)
		Game:FireEvent("gui.hud.show")
	end
end

function Scoreboard:LocalPlayerInput(args)
	if self.open and (Game:GetState() == GUIState.Game or Game:GetState() == 0) then return false end
end

function Scoreboard:MouseScroll(args)
	if self.open and Render.Width * 0.05 <= Mouse:GetPosition().x and Mouse:GetPosition().x <= Render.Width * 0.95 and (Render.Height * 0.05) + ScoreboardConfig.TopBarHeight <= Mouse:GetPosition().y and Mouse:GetPosition().y <= Render.Height * 0.95 then
		local contentHeight = (table.count(self.playerData) * (ScoreboardConfig.RowHeight + ScoreboardConfig.RowSpacing)) - ScoreboardConfig.RowSpacing
		local containerHeight = (Render.Height * 0.9) - ScoreboardConfig.TopBarHeight

		self.scrollOffset = math.clamp(self.scrollOffset + (args.delta * 16), (contentHeight > containerHeight and -contentHeight + containerHeight or 0), 0)
	end
end

function Scoreboard:PlayerNetworkValueChange(args)
	if not self.playerData[args.player:GetSteamId().id] then
		self.playerData[args.player:GetSteamId().id] = {
			name = args.player:GetName(),
			image = args.player:GetAvatar(),
			ping = -1,
			color = args.player:GetColor()
		}
	end


	self.playerData[args.player:GetSteamId().id][args.key] = args.value
end

function Scoreboard:Render()
	if Game:GetState() ~= GUIState.Game and Game:GetState() ~= 0 or not self.open then return end

	Render:SetClip(true, Render.Size * 0.05, Render.Size *  0.9)
	Render:FillArea(Vector2.Zero, Render.Size, Color(0, 0, 0, 155))
	
	Render:FillArea(Vector2(0, Render.Height * 0.05), Vector2(Render.Width, ScoreboardConfig.TopBarHeight), Color(0, 0, 0, 155))
	Render:FillArea(Vector2(0, (Render.Height * 0.05) + ScoreboardConfig.TopBarHeight - ScoreboardConfig.TopBarBorderHeight), Vector2(Render.Width, ScoreboardConfig.TopBarBorderHeight), Color(255, 255, 255, 65))
	Render:DrawText((Render.Size * 0.05) + ((Vector2(Render.Width * 0.9, ScoreboardConfig.TopBarHeight) - Render:GetTextSize(ScoreboardConfig.TopBarMessage, ScoreboardConfig.TopBarFontSize)) / 2), ScoreboardConfig.TopBarMessage, Color.White, ScoreboardConfig.TopBarFontSize)
	Render:SetClip(true, Vector2(Render.Width * 0.05, (Render.Height * 0.05) + ScoreboardConfig.TopBarHeight), (Render.Size * 0.9) - Vector2(0, ScoreboardConfig.TopBarHeight))

	local contentHeight = (table.count(self.playerData) * (ScoreboardConfig.RowHeight + ScoreboardConfig.RowSpacing)) - ScoreboardConfig.RowSpacing
	local containerHeight = (Render.Height * 0.9) - ScoreboardConfig.TopBarHeight
	local viewportOffset = 0

	for k, player in pairs(self.playerData) do
		local size = Vector2((Render.Width * 0.9) - (contentHeight > containerHeight and 16 or 0), ScoreboardConfig.RowHeight)
		local offset = Vector2(Render.Width * 0.05, (Render.Height * 0.05) + (viewportOffset * (size.y + 2)) + self.scrollOffset + ScoreboardConfig.TopBarHeight)
		
		if Render.Height * 0.05 <= offset.y + size.y and offset.y <= Render.Height * 0.95 then
			Render:FillArea(offset, size, Color(0, 0, 0, 155))
			player.image:Draw(offset + (Vector2.One * ScoreboardConfig.RowPadding), Vector2(size.y - (ScoreboardConfig.RowPadding * 2), size.y - (ScoreboardConfig.RowPadding * 2)), Vector2.Zero, Vector2.One)
			Render:DrawText(offset + Vector2(size.y + (ScoreboardConfig.RowPadding * 2), (size.y - ScoreboardConfig.RowFontSize) / 2), player.name, player.color, ScoreboardConfig.RowFontSize)
			Render:DrawText(offset + Vector2(size.x - Render:GetTextWidth(player.ping .. "ms", ScoreboardConfig.RowFontSize) - (ScoreboardConfig.RowPadding * 2), (size.y - ScoreboardConfig.RowFontSize) / 2), player.ping .. "ms", Color.White, ScoreboardConfig.RowFontSize)
		elseif offset.y > Render.Height * 0.95 then
			break
		end

		viewportOffset = viewportOffset + 1
	end

	if contentHeight > containerHeight then
		Render:FillArea(Vector2((Render.Width * 0.95) - 16, (Render.Height * 0.05) + ScoreboardConfig.TopBarHeight), Vector2(16, containerHeight), Color(25, 25, 25, 155))
		Render:FillArea(Vector2((Render.Width * 0.95) - 16, (Render.Height * 0.05) + ScoreboardConfig.TopBarHeight) + Vector2(0, (containerHeight - ((containerHeight - 4) * ((containerHeight - 4) / contentHeight))) * (-self.scrollOffset / (contentHeight - containerHeight))) + (Vector2.One * 2), Vector2(12, (containerHeight - 4) * ((containerHeight - 4) / contentHeight)), Color(255, 255, 255, 50))
	end

	Render:SetClip(false)
end

scoreboard = Scoreboard()