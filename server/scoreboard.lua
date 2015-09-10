class "Scoreboard"

function Scoreboard:__init()
	self.timer = Timer()

	Events:Subscribe("PreTick", self, self.PreTick)
end

function Scoreboard:PreTick()
	if self.timer:GetSeconds() > 5 then
		for player in Server:GetPlayers() do
			player:SetNetworkValue("ping", player:GetPing())
		end

		self.timer:Restart()
	end
end

scoreboard = Scoreboard()