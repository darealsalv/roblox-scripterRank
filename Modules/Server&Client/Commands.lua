local m = {}

local permissionsModule = require(script.Parent.Parent:WaitForChild("Server&Client"):WaitForChild("Permissions"))

m.CommandSettings = {
	BlindnessDuration = 10,
	VIPCommandsEnabled = false,
	HealCooldown = 10,
	HealLimit = 100,
}

m.Comandos = {
	["OwnerCommands"] = {
		["Shutdown"] = "shutdown",
		["MegaAnnounce"] = "megaannounce",
	},

	["AdminCommands"] = {
		["Ban"] = "ban",
		["BanAsync"] = "banasync",
		["Unban"] = "unban",
		["SetRank"] = "setrank",
		["RemoveRank"] = "removerank",
		["ServerAnnounce"] = "serverannounce",
	},

	["Mod+Commands"] = {
		["Freeze"] = "freeze",
		["Unfreeze"] = "unfreeze",
		["Refresh"] = "refresh",
		["Invisible"] = "invisible",
		["Visible"] = "visible",
	},

	["ModCommands"] = {
		["Spectate"] = "spectate",
		["Unspectate"] = "unspectate",
		["Kill"] = "kill",
		["Explode"] = "explode",
		["FF"] = "ff",
		["UnFF"] = "unff",
		["Speed"] = "speed",
		["Jump"] = "jump",
		["Kick"] = "kick",
		["Goto"] = "goto",
		["Bring"] = "bring",
		["Mark"] = "mark",
		["UnMark"] = "unmark",
		["BlindnessDuration"] = "blinddur",
		["HealCooldown"] = "healcd",
		["ToggleVipCommands"] = "togglevip",
	},

	["VipCommands"] = {
		["Heal"] = "heal",
		["Blindness"] = "blind"
	},

	["PlayerCommands"] = {
		["Logs"] = "logs",
		["Help"] = "help",
	}
}

m.CommandsForGui = {
	["OwnerCommands"] = {
		[1] = {
			Command = "shutdown",
			Parameters = nil,
			Description = "Shuts down ALL the servers in-game.",
			ExampleCommand = "shutdown",
			useDoubleDescription = false
		},
		[2] = {
			Command = "megaannounce",
			Parameters = "<Message>",
			Description = "Displays an announcement across all active servers in your game.",
			ExampleCommand = "megaannounce Hey boysss!",
			useDoubleDescription = false
		},
	},

	["AdminCommands"] = {
		[1] = {
			Command = "ban",
			Parameters = "<Player> <Time> <Reason>",
			Description = "Bans a player from the same server that you are at.",
			ExampleCommand = "ban Roblox 30min Some reason idk",
			useDoubleDescription = true,
			MiniDescription1 = "Set time to -1 for infinite",
			MiniDescription2 = "Time format must be like this: 1s, 20min, 1d, 2m, 3y"
		},
		[2] = {
			Command = "banasync",
			Parameters = "<UserId> <Time> <Reason>",
			Description = "Bans a player without needing to be in the same server (recommended).",
			ExampleCommand = "ban 8163017741 30min Some reason idk",
			useDoubleDescription = true,
			MiniDescription1 = "Set time to -1 for infinite",
			MiniDescription2 = "Time format must be like this: 1s, 20min, 1d, 2m, 3y"
		},
		[3] = {
			Command = "unban",
			Parameters = "<PlayerOrUserId>",
			Description = "Unbans a banned player.",
			ExampleCommand = "unban Roblox",
			useDoubleDescription = false
		},
		[4] = {
			Command = "setrank",
			Parameters = "<PlayerOrUserId> <Rank>",
			Description = "Set the moderator rank of a player.",
			ExampleCommand = "setrank Roblox mod+",
			useDoubleDescription = false
		},
		[5] = {
			Command = "removerank",
			Parameters = "<PlayerOrUserId>",
			Description = "Removes any moderator rank from a player, turning them to the 'Player' rank.",
			ExampleCommand = "removerank Roblox",
			useDoubleDescription = false
		},
		[6] = {
			Command = "serverannounce",
			Parameters = "<Message>",
			Description = "Displays an announcement on all players screen from across the server.",
			ExampleCommand = "serverannounce roblox is cool!",
			useDoubleDescription = false
		},
	},

	["Mod+Commands"] = {
		[1] = {
			Command = "freeze",
			Parameters = "<Player>",
			Description = "Stops a player from moving in the game.",
			ExampleCommand = "freeze Roblox",
			useDoubleDescription = false
		},
		[2] = {
			Command = "unfreeze",
			Parameters = "<Player>",
			Description = "Allows a player to move in the game.",
			ExampleCommand = "unfreeze Roblox",
			useDoubleDescription = false
		},
		[3] = {
			Command = "refresh",
			Parameters = "<Player>",
			Description = "Kills a player and tries to spawn them back right where they died.",
			ExampleCommand = "refresh Roblox",
			useDoubleDescription = false
		},
		[4] = {
			Command = "invisible",
			Parameters = "<Player>",
			Description = "Attempts to make a player fully invisible.",
			ExampleCommand = "invisible Roblox",
			useDoubleDescription = false
		},
		[5] = {
			Command = "visible",
			Parameters = "<Player>",
			Description = "Reverts the Invisible command from a player.",
			ExampleCommand = "visible Roblox",
			useDoubleDescription = false
		},
	},

	["ModCommands"] = {
		[1] = {
			Command = "spectate",
			Parameters = "<Player>",
			Description = "Makes your camera follow another player's character.",
			ExampleCommand = "spectate Roblox",
			useDoubleDescription = false
		},
		
		[2] = {
			Command = "unspectate",
			Parameters = "",
			Description = "Makes your camera stop following any other player's character.",
			ExampleCommand = "unspectate",
			useDoubleDescription = false
		},
		
		[3] = {
			Command = "kill",
			Parameters = "<Player>",
			Description = "Kills a player.",
			ExampleCommand = "kill Roblox",
			useDoubleDescription = false
		},

		[4] = {
			Command = "explode",
			Parameters = "<Player>",
			Description = "Explodes a player.",
			ExampleCommand = "explode Roblox",
			useDoubleDescription = false
		},
		
		[5] = {
			Command = "ff",
			Parameters = "<Player>",
			Description = "Makes a player unable to receive damage.",
			ExampleCommand = "ff Roblox",
			useDoubleDescription = false
		},

		[6] = {
			Command = "unff",
			Parameters = "<Player>",
			Description = "Makes a player be able to receive damage.",
			ExampleCommand = "unff Roblox",
			useDoubleDescription = false
		},
		
		[7] = {
			Command = "speed",
			Parameters = "<Player> <Number>",
			Description = "Changes a player speed.",
			ExampleCommand = "speed Roblox 16",
			useDoubleDescription = false
		},
		
		[8] = {
			Command = "jump",
			Parameters = "<Player> <Number>",
			Description = "Changes the jump force of a player.",
			ExampleCommand = "jump Roblox 100",
			useDoubleDescription = false
		},
		
		[9] = {
			Command = "kick",
			Parameters = "<Player> <Reason>",
			Description = "Kicks a player.",
			ExampleCommand = "kick Roblox Some reason idk",
			useDoubleDescription = false
		},
		
		[10] = {
			Command = "goto",
			Parameters = "<Player>",
			Description = "Teleports you to a player.",
			ExampleCommand = "goto Roblox",
			useDoubleDescription = false
		},
		
		[11] = {
			Command = "bring",
			Parameters = "<Player>",
			Description = "Teleports a player to you.",
			ExampleCommand = "bring Roblox",
			useDoubleDescription = false
		},
		
		[12] = {
			Command = "mark",
			Parameters = "<Player>",
			Description = "Marks a player with a highlight",
			ExampleCommand = "mark Roblox",
			useDoubleDescription = false
		},
		
		[13] = {
			Command = "unmark",
			Parameters = "<Player>",
			Description = "Undo marks a player with a highlight",
			ExampleCommand = "unmark Roblox",
			useDoubleDescription = false
		},
		
		[14] = {
			Command = "blinddur",
			Parameters = "<Number>",
			Description = "Sets the duration of the blindness comand, 10 is the default.",
			ExampleCommand = "blinddur 10",
			useDoubleDescription = false
		},
		
		[15]  = {
			Command = "healcd",
			Parameters = "<Number>",
			Description = "Sets the cooldown for a player to use the heal command.",
			ExampleCommand = "healcd 15",
			useDoubleDescription = false
		},
		
		[16] = {
			Command = "togglevip",
			Parameters = "<Boolean>",
			Description = "Toggles the VIP Commands to be enabled or not.",
			ExampleCommand = "togglevip true",
			useDoubleDescription = false
		},
	},

	["VipCommands"] = {
		[1] = {
			Command = "heal",
			Parameters = "<Player> <Number>",
			Description = nil,
			ExampleCommand = "heal Roblox 30",
			useDoubleDescription = true,
			MiniDescription1 = "Heals a player.",
			MiniDescription2 = "[This command has cooldown!]"
		},
		
		[2] = {
			Command = "blind",
			Parameters = "<Player>",
			Description = nil,
			ExampleCommand = "blind Roblox",
			useDoubleDescription = true,
			MiniDescription1 = "Makes a player's screen black for "..m.CommandSettings.BlindnessDuration.." seconds.", -- ik this is wrong but im lazy to change it, it works anyway
			MiniDescription2 = "[This command has cooldown!]"
		},
	},

	["PlayerCommands"] = {
		[1] = {
			Command = "help",
			Parameters = nil,
			Description = "Opens/Refreshes the commands page.",
			ExampleCommand = "help",
			useDoubleDescription = false
		},
		
		[2] = {
			Command = "logs",
			Parameters = nil,
			Description = "Opens or Closes the commands logs.",
			ExampleCommand = "logs",
			useDoubleDescription = false
		},
	}
}


return m
