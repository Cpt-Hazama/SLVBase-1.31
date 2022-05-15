function ENT:GenerateInventory(owner)
	if self.inventory then return end
	self.inventory = {}
	if !self.genericItem then return end
	self:AddToInventory(self.genericItem)
end