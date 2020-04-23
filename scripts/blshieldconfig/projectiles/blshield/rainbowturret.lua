require "/scripts/vec2.lua"
require "/scripts/util.lua"

function init()
  self.range = config.getParameter("range", 20)
  self.rotationRate = config.getParameter("rotationRate")
  self.trackingLimit = config.getParameter("trackingLimit")
  self.sourceEntity = projectile.sourceEntity()
  self.queryParameters = {
    withoutEntityId = self.sourceEntity,
    includedTypes = {"creature","npc"},
    order = "nearest"
  }
  
  self.projectileTypes = projectile.getParameter("projectileTypes",{"blturretBullet"})
  self.damageKinds = projectile.getParameter("damageKinds",{"default"})
  self.damageEffects = projectile.getParameter("damageEffects",{"default"})
  self.currentKind = 1
  self.currentProjectile = 1
  
  self.power = projectile.power()
  self.fireRate = projectile.getParameter("fireRate",0.5)
  self.fireRateBase = self.fireRate
  self.range = projectile.getParameter("range",20)
  self.bulletPower = self.power*self.fireRate/projectile.timeToLive()
  projectile.setPower(0)
end

function update(dt)
  if self.fireRate > 0 then self.fireRate = self.fireRate - dt  return end
  self.fireRate = self.fireRateBase
  local pos = mcontroller.position()

  local candidates = world.entityQuery(pos, self.range, self.queryParameters)
  if #candidates == 0 then return end

  for _, candidate in ipairs(candidates) do
    if world.entityCanDamage(self.sourceEntity, candidate) then
      local canPos = world.entityPosition(candidate)
      if not world.lineTileCollision(pos, canPos) then
        local toTarget = world.distance(canPos, pos)
        local toTargetAngle = util.angleDiff(vec2.angle({1,0}), vec2.angle(toTarget))
		
        local rotateAngle = math.max(dt * -self.rotationRate, math.min(toTargetAngle, dt * self.rotationRate))
        local vel = vec2.rotate({75,0}, rotateAngle)
		local damageConfig = {
				power = self.bulletPower,
				speed = 75,
				damageKind = self.damageKinds[self.currentKind],
				statusEffects = {self.damageEffects[self.currentKind]}
			  }
		world.spawnProjectile(self.projectileTypes[self.currentProjectile],vec2.add(pos,vec2.norm(vel)), self.sourceEntity, vel, false, damageConfig)
		if self.currentKind < #self.damageKinds then self.currentKind = self.currentKind + 1 else self.currentKind = 1 end
		if self.currentProjectile < #self.projectileTypes then self.currentProjectile = self.currentProjectile + 1 else self.currentProjectile = 1 end
        break
      end
    end
  end
  mcontroller.setRotation(0)
end
