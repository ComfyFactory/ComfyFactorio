
local Balance = require 'maps.pirates.balance'
local inspect = require 'utils.inspect'.inspect
local Memory = require 'maps.pirates.memory'
local Math = require 'maps.pirates.math'
local Common = require 'maps.pirates.common'
local Utils = require 'maps.pirates.utils_local'
local CoreData = require 'maps.pirates.coredata'
local Server = require 'utils.server'

local Public = {}
local enum = {
	DECKHAND = 1,
	FISHERMAN = 2,
	SCOUT = 3,
	SAMURAI = 4,
	MERCHANT = 5,
	SHORESMAN = 6,
	BOATSWAIN = 7,
	PROSPECTOR = 8,
}
Public.enum = enum

Public.Class_List = {
	enum.DECKHAND,
	enum.FISHERMAN,
	enum.SCOUT,
	enum.SAMURAI,
	enum.MERCHANT,
	enum.SHORESMAN,
	enum.BOATSWAIN,
	enum.PROSPECTOR,
}

Public.display_form = {
	[enum.DECKHAND] = 'Deckhand',
	[enum.FISHERMAN] = 'Fisherman',
	[enum.SCOUT] = 'Scout',
	[enum.SAMURAI] = 'Samurai',
	[enum.MERCHANT] = 'Merchant',
	[enum.SHORESMAN] = 'Shoresman',
	[enum.BOATSWAIN] = 'Boatswain',
	[enum.PROSPECTOR] = 'Prospector',
}
Public.explanation = {
	[enum.DECKHAND] = 'They move faster and generate iron ore for the ship whilst onboard above deck, but move slower offboard.',
	[enum.FISHERMAN] = 'They fish at greater distance.',
	[enum.SCOUT] = 'They are faster, but frail and deal much less damage.',
	[enum.SAMURAI] = 'They are tough, and when they have no weapon equipped they fight well by melee, but poorly otherwise.',
	[enum.MERCHANT] = 'They generate 40 coins per league, but they are frail.',
	[enum.SHORESMAN] = 'They move slightly faster and generate iron ore for the ship whilst offboard, but move slower onboard.',
	[enum.BOATSWAIN] = 'They move faster and generate lots of ore for the ship whilst onboard below deck, but move slower offboard.',
	[enum.PROSPECTOR] = 'They find more resources when handmining ore.',
}

return Public