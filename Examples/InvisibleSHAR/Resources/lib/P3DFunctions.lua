if P3D == nil then Alert("P3D Functions loaded with no P3D table present.") end
local P3D = P3D
function MakeCharacterInvisible(Original)
	local RootChunk = P3D.P3DChunk:new{Raw = Original}
	local modified = false
	for idx, id in RootChunk:GetChunkIndexes(nil) do
		if not Settings.IncludeCharShadows and id == P3D.Identifiers.Composite_Drawable then
			local CompDrawChunk = P3D.CompositeDrawableP3DChunk:new{Raw=RootChunk:GetChunkAtIndex(idx)}
			for idx2 in CompDrawChunk:GetChunkIndexes(nil) do
				CompDrawChunk:RemoveChunkAtIndex(idx2)
			end
			RootChunk:SetChunkAtIndex(idx, CompDrawChunk:Output())
			modified = true
		elseif id ~= P3D.Identifiers.Skeleton then
			RootChunk:RemoveChunkAtIndex(idx)
			modified = true
		end
	end
	return RootChunk:Output(), modified
end

local ROOT_CHUNKS = {P3D.Identifiers.Static_Entity, P3D.Identifiers.Inst_Stat_Phys, P3D.Identifiers.Dyna_Phys, P3D.Identifiers.Breakable_Object, P3D.Identifiers.World_Sphere, P3D.Identifiers.Inst_Stat_Entity}
function MakeModelInvisible(Original)
	local RootChunk = P3D.P3DChunk:new{Raw = Original}
	local modified = false
	for RootIdx, RootID in RootChunk:GetChunkIndexes(nil) do
		if ExistsInTbl(ROOT_CHUNKS, RootID) then
			RootChunk:SetChunkAtIndex(RootIdx, MakeModelInvisibleProcessRoot(RootChunk:GetChunkAtIndex(RootIdx)))
			modified = true
		elseif RootID == P3D.Identifiers.Mesh then
			RootChunk:SetChunkAtIndex(RootIdx, MakeModelInvisibleProcessMesh(RootChunk:GetChunkAtIndex(RootIdx)))
			modified = true
		elseif RootID == P3D.Identifiers.Anim_Dyna_Phys then
			local AnimDynaPhysChunk = P3D.AnimDynaPhysP3DChunk:new{Raw = RootChunk:GetChunkAtIndex(RootIdx)}
			for idx in AnimDynaPhysChunk:GetChunkIndexes(P3D.Identifiers.Anim_Obj_Wrapper) do
				local AnimObjWrapperChunk = P3D.AnimObjWrapperP3DChunk:new{Raw = AnimDynaPhysChunk:GetChunkAtIndex(idx)}
				for idx2 in AnimObjWrapperChunk:GetChunkIndexes(P3D.Identifiers.Mesh) do
					AnimObjWrapperChunk:SetChunkAtIndex(idx2, MakeModelInvisibleProcessMesh(AnimObjWrapperChunk:GetChunkAtIndex(idx2)))
				end
				AnimDynaPhysChunk:SetChunkAtIndex(idx, AnimObjWrapperChunk:Output())
			end
			RootChunk:SetChunkAtIndex(RootIdx, AnimDynaPhysChunk:Output())
			modified = true
		elseif RootID == P3D.Identifiers.Old_Billboard_Quad_Group then
			local OldBillboardQuadGroupChunk = P3D.OldBillboardQuadGroupP3DChunk:new{Raw = RootChunk:GetChunkAtIndex(RootIdx)}
			for idx in OldBillboardQuadGroupChunk:GetChunkIndexes(P3D.Identifiers.Old_Billboard_Quad) do
				local OldBillboardQuadChunk = P3D.OldBillboardQuadP3DChunk:new{Raw = OldBillboardQuadGroupChunk:GetChunkAtIndex(idx)}
				OldBillboardQuadChunk.Width = 0
				OldBillboardQuadChunk.Height = 0
				OldBillboardQuadGroupChunk:SetChunkAtIndex(idx, OldBillboardQuadChunk:Output())
			end
			RootChunk:SetChunkAtIndex(RootIdx, OldBillboardQuadGroupChunk:Output())
			modified = true
		elseif RootID == P3D.Identifiers.Multi_Controller then
			local MultiControllerChunk = P3D.MultiControllerP3DChunk:new{Raw = RootChunk:GetChunkAtIndex(RootIdx)}
			for idx in MultiControllerChunk:GetChunkIndexes(P3D.Identifiers.Multi_Controller_Tracks) do
				local MultiControllerTracksChunk = P3D.MultiControllerTracksP3DChunk:new{Raw = MultiControllerChunk:GetChunkAtIndex(idx)}
				for i=#MultiControllerTracksChunk.Tracks,1,-1 do
					if MultiControllerTracksChunk.Tracks[i].Name:sub(1,4) ~= "PTRN" then
						table.remove(MultiControllerTracksChunk.Tracks, i)
					end
				end
				MultiControllerChunk:SetChunkAtIndex(idx, MultiControllerTracksChunk:Output())
			end
			RootChunk:SetChunkAtIndex(RootIdx, MultiControllerChunk:Output())
			modified = true
		end
	end
	return RootChunk:Output(), modified
end
function MakeModelInvisibleProcessRoot(Original)
	local RootChunk = P3D.P3DChunk:new{Raw = Original}
	for idx in RootChunk:GetChunkIndexes(P3D.Identifiers.Mesh) do
		RootChunk:SetChunkAtIndex(idx, MakeModelInvisibleProcessMesh(RootChunk:GetChunkAtIndex(idx)))
	end
	if LensFlare and RootChunk.ChunkType == P3D.Identifiers.World_Sphere then
		for idx in RootChunk:GetChunkIndexes(P3D.Identifiers.Lens_Flare) do
			local LensFlareChunk = P3D.LensFlareP3DChunk:new{Raw = RootChunk:GetChunkAtIndex(idx)}
			for idx2 in LensFlareChunk:GetChunkIndexes(P3D.Identifiers.Mesh) do
				LensFlareChunk:SetChunkAtIndex(idx2, MakeModelInvisibleProcessMesh(LensFlareChunk:GetChunkAtIndex(idx2)))
			end
			RootChunk:SetChunkAtIndex(idx, LensFlareChunk:Output())
		end
	end
	return RootChunk:Output()
end
function MakeModelInvisibleProcessMesh(Original)
	local MeshChunk = P3D.MeshP3DChunk:new{Raw = Original}
	for idx in MeshChunk:GetChunkIndexes(P3D.Identifiers.Old_Primitive_Group) do
		MeshChunk:RemoveChunkAtIndex(idx)
	end
	return MeshChunk:Output()
end