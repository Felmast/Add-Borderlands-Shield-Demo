require "/scripts/util.lua"
require "/scripts/randgenblshieldsutil.lua"

function init()
	self.initialized = false
	script.setUpdateDelta(1)
	blshieldutil.init()
end

function update(dt)
	if not self.initialized then
		local parts = status.resource("blshieldparts")
		if parts == 9 then
			initialize()
			self.initialized = true
		elseif parts == 7 then
			addStats()
		end
		return
	end
	
	self.recharged = self.currCapacity > 0
	self.currCapacity = status.resource("damageAbsorption")
	if self.currCapacity < self.lastCapacity and self.storedDamage < self.maxDamage then
		local damage = (self.lastCapacity - self.currCapacity)
		self.storedDamage = self.storedDamage + (damage*self.efficiency)
		if self.storedDamage > self.maxDamage then self.storedDamage = self.maxDamage end
	end
	if self.currCapacity <= 0 and self.recharged then
		self.recharged = false
		spawnTurret()
		self.storedDamage = 0
	end
	updateAnimation()
	self.lastCapacity = self.currCapacity
end

function spawnTurret()
	local dir = math.random(-1,1)
	local damageConfig = {
				power = self.storedDamage,
				fireRate = self.fireRate,
				range = self.range-0.1,
				speed = 10,
				damageKinds = {"flamethrower","iceplasma","poisonplasma","electricplasma","slagplasma"},
				damageEffects = {"burning","frostslow","weakpoison","electrified","slagged"},
				timeToLive = 10
			  }
	world.spawnProjectile(self.turretProjectile, entity.position(), effect.sourceEntity(), {dir*22,15}, false, damageConfig)

end

function initialize()
	initializeShield()
	math.randomseed(world.time())
	self.storedDamage = 0
	self.efficiency = self.special[1]
	self.maxDamage = self.special[2]
	self.range = self.special[3]
	self.fireRate = self.special[4]
	
	
	self.turretProjectile = "rainbowfactoryprojectile"
	self.currCapacity = status.resource("damageAbsorption")
	self.lastCapacity = self.currCapacity
	
	sb.logInfo("Shield type activated")
end

function addStats()
	addStatsShield()
end

function uninit() 
	--if self.effectId then effect.removeStatModifierGroup(self.effectId) end
end

function updateAnimation()
	local percentage = self.storedDamage/self.maxDamage
	if percentage <= 0 then 
		animator.setAnimationState("barshield", "off")
	elseif percentage >= 1 then
		animator.setAnimationState("barshield", "charge26") 
		if not status.statusProperty("toggleblshieldbarfull", true) then 
			animator.setAnimationState("barshield", "off") 
		end
	else
		percentage = math.floor(percentage*26)
		animator.setAnimationState("barshield", "charge"..percentage)
		if not status.statusProperty("toggleblshieldbarfull", true) then 
			animator.setAnimationState("barshield", "off") 
		end
	end
	if not status.statusProperty("toggleblshieldbar", true) then
		animator.setAnimationState("barshield", "off")
	end
end
