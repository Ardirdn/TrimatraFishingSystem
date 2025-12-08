--[[
    ROBLOX MUSIC PLAYER - MODIFIED VERSION
    Place in StarterPlayer > StarterPlayerScripts
    Requires: TopbarPlus module, MusicConfig, existing MusicPlayer GUI in StarterGui
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- No longer using TopbarPlus
local MusicConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("MusicConfig"))

-- RemoteEvents for Favorites
local musicRemoteFolder = ReplicatedStorage:WaitForChild("MusicRemotes")
local toggleFavoriteMusicEvent = musicRemoteFolder:WaitForChild("ToggleFavorite")
local getFavoritesMusicFunc = musicRemoteFolder:WaitForChild("GetFavorites")

-- Wait for MusicPlayer GUI
local screenGui = playerGui:WaitForChild("MusicPlayer")

-- ==================== GET UI REFERENCES ====================
-- Main Panel
local mainPanel = screenGui:WaitForChild("MainPanel")
local buttonsPanel = mainPanel:WaitForChild("ButtonsPanel")
local openLibraryButton = buttonsPanel:WaitForChild("OpenLibraryButton")
local trackButtonFrame = buttonsPanel:WaitForChild("TrackButton")
local loopButton = trackButtonFrame:WaitForChild("LoopButton")
local nextButton = trackButtonFrame:WaitForChild("NextButton")
local playPauseButton = trackButtonFrame:WaitForChild("PlayPauseButton")
local prevButton = trackButtonFrame:WaitForChild("PrevButton")
local volumeButton = trackButtonFrame:WaitForChild("VolumeButton")
local volumePanel = volumeButton:WaitForChild("VolumePanel")
local volumeSlider = volumePanel:WaitForChild("Slider")
local volumeFillBar = volumeSlider:WaitForChild("FillBar")
local volumeFillCircle = volumeSlider:WaitForChild("FillCircle")
local volumeMinButton = volumePanel:WaitForChild("MinButton")
local volumeAddButton = volumePanel:WaitForChild("AddButton")

local playingMusicPanel = mainPanel:WaitForChild("PlayingMusicPanel")
local musicInfo = playingMusicPanel:WaitForChild("MusicInfo")
local favButtonArea = musicInfo:WaitForChild("FavButtonArea")
local favButton = favButtonArea:WaitForChild("FavButton")
local trackInfo = musicInfo:WaitForChild("TrackInfo")
local playlistNameLabel = trackInfo:WaitForChild("PlaylistName")
local songNameLabel = trackInfo:WaitForChild("SongName")
local timeline = playingMusicPanel:WaitForChild("Timeline")

-- MyLibrary Panel
local myLibraryPanel = screenGui:WaitForChild("MyLibraryPanel")
local categoryFrame = myLibraryPanel:WaitForChild("Category")
local allButton = categoryFrame:WaitForChild("AllButton")
local playlistButton = categoryFrame:WaitForChild("PlaylistButton")
local favoritesButton = categoryFrame:WaitForChild("FavoritesButton")

local allPanel = myLibraryPanel:WaitForChild("AllPanel")
local allMusicList = allPanel:WaitForChild("MusicList")
local musicCardTemplate = allMusicList:WaitForChild("MusicCard")
musicCardTemplate.Visible = false

local favoritesPanel = myLibraryPanel:WaitForChild("FavoritesPanel")
local favoritesMusicList = favoritesPanel:WaitForChild("MusicList")

local playlistPanel = myLibraryPanel:WaitForChild("PlaylistPanel")
local playlistScroll = playlistPanel:WaitForChild("Playlist")
local playlistCardTemplate = playlistScroll:WaitForChild("PlaylistCard")
playlistCardTemplate.Visible = false

-- Playlist Popup Panel
local playlistPopupPanel = screenGui:WaitForChild("PlaylistPopupPanel")
local popupHeader = playlistPopupPanel:WaitForChild("Header")
local popupCloseButton = popupHeader:WaitForChild("CloseButton")
local popupBackButton = popupHeader:WaitForChild("BackButton")
local PlaylistListPanel = playlistPopupPanel:WaitForChild("PlaylistListPanel")
local popupMusicList = playlistPanel:WaitForChild("Playlist") -- atau nama ScrollingFrame di popup
local popupPlaylistTitle = popupHeader:WaitForChild("PlaylistTitle") -- TextLabel untuk judul playlist


-- Widget Panel
local widgetPanel = screenGui:WaitForChild("WidgetPanel")
local widgetButtonsPanel = widgetPanel:WaitForChild("ButtonsPanel")
local widgetPlayingMusicPanel = widgetButtonsPanel:WaitForChild("PlayingMusicPanel")
local widgetMusicInfo = widgetPlayingMusicPanel:WaitForChild("MusicInfo")
local widgetFavButton = widgetMusicInfo:WaitForChild("FavButton"):WaitForChild("ImageButton")
local widgetTrackInfo = widgetMusicInfo:WaitForChild("TrackInfo")
local widgetPlaylistName = widgetTrackInfo:WaitForChild("PlaylistName")
local widgetSongName = widgetTrackInfo:WaitForChild("SongName")
local widgetTimeline = widgetPlayingMusicPanel:WaitForChild("Timeline")
local widgetSlider = widgetTimeline:WaitForChild("Slider")
local widgetFillBar = widgetSlider:WaitForChild("FillBar")
local widgetFillCircle = widgetSlider:WaitForChild("FillCircle")
local widgetTimeInfo = widgetTimeline:WaitForChild("TimeInfo")
local widgetCurrentTime = widgetTimeInfo:WaitForChild("CurrentTime")
local widgetRemainingTime = widgetTimeInfo:WaitForChild("RemainingTime")

local widgetTrackButton = widgetButtonsPanel:WaitForChild("TrackButton")
local widgetLoopButton = widgetTrackButton:WaitForChild("LoopButton")
local widgetNextButton = widgetTrackButton:WaitForChild("NextButton")
local widgetPlayPauseButton = widgetTrackButton:WaitForChild("PlayPauseButton")
local widgetPrevButton = widgetTrackButton:WaitForChild("PrevButton")
local widgetVolumeButton = widgetTrackButton:WaitForChild("VolumeButton")
local widgetVolumePanel = widgetVolumeButton:WaitForChild("VolumePanel")
local widgetVolumeSlider = widgetVolumePanel:WaitForChild("Slider")
local widgetVolumeFillBar = widgetVolumeSlider:WaitForChild("FillBar")
local widgetVolumeFillCircle = widgetVolumeSlider:WaitForChild("FillCircle")
local widgetVolumeMinButton = widgetVolumePanel:WaitForChild("MinButton")
local widgetVolumeAddButton = widgetVolumePanel:WaitForChild("AddButton")

-- Queue Panel
local queuePanel = screenGui:WaitForChild("QueuePanel")
local queueListPanel = queuePanel:WaitForChild("QueueListPanel")
local queueScroll = queueListPanel:WaitForChild("Queue")



-- ==================== USE HUD BUTTON TEMPLATE (RIGHT SIDE) ====================

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local hudGui = playerGui:WaitForChild("HUD", 10)
local rightFrame = hudGui and hudGui:FindFirstChild("Right")
local buttonTemplate = rightFrame and rightFrame:FindFirstChild("ButtonTemplate")

local floatingButton = nil
local isMusicPanelOpen = false

if buttonTemplate then
	-- ✅ Hide the original template
	buttonTemplate.Visible = false
	
	-- Clone the template
	local buttonContainer = buttonTemplate:Clone()
	buttonContainer.Name = "MusicButton"
	buttonContainer.Visible = true
	buttonContainer.LayoutOrder = 2 -- Second button on right
	buttonContainer.BackgroundTransparency = 1 -- ✅ Transparent container
	buttonContainer.Parent = rightFrame
	
	-- Get references
	floatingButton = buttonContainer:FindFirstChild("ImageButton")
	local buttonText = buttonContainer:FindFirstChild("TextLabel")
	
	-- Set button properties
	if floatingButton then
		floatingButton.Image = "rbxassetid://97131431743901" -- Music icon
		floatingButton.BackgroundTransparency = 1 -- ✅ Transparent button
	end
	
	if buttonText then
		buttonText.Text = "Music"
	end
	

else
	-- Fallback: Create button manually if template not found
	warn("[MUSIC] HUD template not found, creating button manually")
	
	floatingButton = Instance.new("ImageButton")
	floatingButton.Name = "MusicButton"
	floatingButton.Size = UDim2.new(0.1, 0, 0.1, 0)
	floatingButton.Position = UDim2.new(0.99, 0, 0.5, 0)
	floatingButton.AnchorPoint = Vector2.new(1, 0)
	floatingButton.BackgroundTransparency = 1
	floatingButton.BorderSizePixel = 0
	floatingButton.Image = "rbxassetid://97131431743901"
	floatingButton.ScaleType = Enum.ScaleType.Fit
	floatingButton.Parent = screenGui
	
	local buttonText = Instance.new("TextLabel")
	buttonText.Size = UDim2.new(1, 0, 0.3, 0)
	buttonText.Position = UDim2.new(0, 0, 1, 2)
	buttonText.BackgroundTransparency = 1
	buttonText.Font = Enum.Font.GothamBold
	buttonText.Text = "Music"
	buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
	buttonText.TextScaled = true
	buttonText.Parent = floatingButton
end

-- Toggle panel on click
if floatingButton then
	floatingButton.MouseButton1Click:Connect(function()
		if isMusicPanelOpen then
			mainPanel.Visible = false
			widgetPanel.Visible = true
			isMusicPanelOpen = false
		else
			mainPanel.Visible = true
			widgetPanel.Visible = false
			isMusicPanelOpen = true
		end
	end)
end

-- Initialize panels visibility
mainPanel.Visible = false
myLibraryPanel.Visible = false
playlistPopupPanel.Visible = false
widgetPanel.Visible = true
queuePanel.Visible = false
volumePanel.Visible = false
widgetVolumePanel.Visible = false

-- ✅ Use existing CloseButton in WidgetPanel to hide widget
local widgetCloseButton = widgetPanel:FindFirstChild("CloseButton")
if widgetCloseButton then
	widgetCloseButton.MouseButton1Click:Connect(function()
		widgetPanel.Visible = false
	end)
end

-- ==================== PANEL NAVIGATION HANDLERS ====================

-- Function to close all music panels
local function closeMusicPlayer()
	mainPanel.Visible = false
	myLibraryPanel.Visible = false
	playlistPopupPanel.Visible = false
	queuePanel.Visible = false
	widgetPanel.Visible = true
	isMusicPanelOpen = false
end

-- Function to show main panel (from sub-panels)
local function showMainPanel()
	mainPanel.Visible = true
	myLibraryPanel.Visible = false
	playlistPopupPanel.Visible = false
	queuePanel.Visible = false
end

-- Function to show library panel
local function showLibraryPanel()
	mainPanel.Visible = false
	myLibraryPanel.Visible = true
	playlistPopupPanel.Visible = false
	queuePanel.Visible = false
end

-- ==================== MAIN PANEL - Close Button ====================
local mainHeader = mainPanel:FindFirstChild("Header")
if mainHeader then
	local mainCloseButton = mainHeader:FindFirstChild("CloseButton")
	if mainCloseButton then
		mainCloseButton.MouseButton1Click:Connect(function()
			closeMusicPlayer()
		end)
	end
end

-- ==================== MY LIBRARY PANEL - Back & Close Buttons ====================
local libraryHeader = myLibraryPanel:FindFirstChild("Header")
if libraryHeader then
	local libraryBackButton = libraryHeader:FindFirstChild("BackButton")
	if libraryBackButton then
		libraryBackButton.MouseButton1Click:Connect(function()
			showMainPanel()
		end)
	end
	
	local libraryCloseButton = libraryHeader:FindFirstChild("CloseButton")
	if libraryCloseButton then
		libraryCloseButton.MouseButton1Click:Connect(function()
			closeMusicPlayer()
		end)
	end
end

-- ==================== PLAYLIST POPUP PANEL - Back & Close Buttons ====================
local popupHeaderRef = playlistPopupPanel:FindFirstChild("Header")
if popupHeaderRef then
	local popupBack = popupHeaderRef:FindFirstChild("BackButton")
	if popupBack then
		popupBack.MouseButton1Click:Connect(function()
			playlistPopupPanel.Visible = false
			myLibraryPanel.Visible = true
		end)
	end
	
	local popupClose = popupHeaderRef:FindFirstChild("CloseButton")
	if popupClose then
		popupClose.MouseButton1Click:Connect(function()
			closeMusicPlayer()
		end)
	end
end

-- ==================== QUEUE PANEL - Back & Close Buttons ====================
local queueHeader = queuePanel:FindFirstChild("Header")
if queueHeader then
	local queueBackButton = queueHeader:FindFirstChild("BackButton")
	if queueBackButton then
		queueBackButton.MouseButton1Click:Connect(function()
			queuePanel.Visible = false
			mainPanel.Visible = true
		end)
	end
	
	local queueCloseButton = queueHeader:FindFirstChild("CloseButton")
	if queueCloseButton then
		queueCloseButton.MouseButton1Click:Connect(function()
			closeMusicPlayer()
		end)
	end
end


-- ==================== MUSIC PLAYER LOGIC ====================
local currentSound = nil
local currentPlaylist = nil
local currentIndex = 1
local playlists = {}
local allSongs = {}
local favorites = {}
local favoritesData = {}
local queue = {}
local isPlaying = false
local isLooping = false
local isDraggingProgress = false
local isDraggingVolume = false
local currentTab = "all"
local currentVolume = MusicConfig.Settings.DefaultVolume
local autoPlayStarted = false

-- Forward declarations
local updateLibraryContent
local updateFavoriteButton
local updateQueueDisplay
local saveFavorites
local loadFavorites
local updatePlayPauseButton
local updateLoopButton
local playSong
local playNextSong
local playPreviousSong

local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

local function loadPlaylists()
	playlists = {}
	allSongs = {}

	for playlistName, playlistData in pairs(MusicConfig.Playlists) do
		local songs = {}

		for _, songData in ipairs(playlistData.Songs) do
			local sound = Instance.new("Sound")
			sound.Name = songData.Title
			sound.SoundId = songData.AssetId
			sound.Volume = currentVolume
			sound.Looped = false
			sound.Parent = workspace

			table.insert(songs, sound)
			table.insert(allSongs, sound)
		end

		if #songs > 0 then
			playlists[playlistName] = songs
		end
	end

	task.wait(1)
end

loadFavorites = function()
	task.spawn(function()
		task.wait(2)

		local success, loadedFavorites = pcall(function()
			return getFavoritesMusicFunc:InvokeServer()
		end)

		if success and loadedFavorites then
			favoritesData = loadedFavorites
			favorites = {}

			for _, id in ipairs(favoritesData) do
				local parts = string.split(id, "/")
				if #parts == 2 then
					local playlistName = parts[1]
					local soundName = parts[2]
					if playlists[playlistName] then
						for _, sound in ipairs(playlists[playlistName]) do
							if sound.Name == soundName then
								table.insert(favorites, sound)
								break
							end
						end
					end
				end
			end



			if myLibraryPanel.Visible then
				updateLibraryContent()
			end
		else
			warn("⚠️ [MUSIC CLIENT] Failed to load favorites")
		end
	end)
end

local function isFavorite(sound)
	for _, fav in ipairs(favorites) do
		if fav == sound then
			return true
		end
	end
	return false
end

local function toggleFavorite(sound)
	local playlistName = "Unknown"

	for pName, songs in pairs(playlists) do
		if table.find(songs, sound) then
			playlistName = pName
			break
		end
	end

	local songId = playlistName.."/"..sound.Name

	if isFavorite(sound) then
		for i, fav in ipairs(favorites) do
			if fav == sound then
				table.remove(favorites, i)
				break
			end
		end

		for i, id in ipairs(favoritesData) do
			if id == songId then
				table.remove(favoritesData, i)
				break
			end
		end
	else
		table.insert(favorites, sound)
		table.insert(favoritesData, songId)
	end

	toggleFavoriteMusicEvent:FireServer(songId)
	updateFavoriteButton()

	if currentTab == "favorites" and myLibraryPanel.Visible then
		updateLibraryContent()
	end
end

updateFavoriteButton = function()
	if currentSound then
		local isFav = isFavorite(currentSound)

		-- Main panel favorite button
		if isFav then
			favButton.BackgroundColor3 = Color3.fromHex("#e20553")
			if favButton:FindFirstChildOfClass("ImageLabel") then
				favButton:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromHex("#ffffff")
			end
		else
			favButton.BackgroundColor3 = Color3.fromHex("#c5d4e2")
			if favButton:FindFirstChildOfClass("ImageLabel") then
				favButton:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromHex("#7a8893")
			end
		end

		-- Widget favorite button
		if isFav then
			widgetFavButton.BackgroundColor3 = Color3.fromHex("#e20553")
			if widgetFavButton:FindFirstChildOfClass("ImageLabel") then
				widgetFavButton:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromHex("#ffffff")
			end
		else
			widgetFavButton.BackgroundColor3 = Color3.fromHex("#c5d4e2")
			if widgetFavButton:FindFirstChildOfClass("ImageLabel") then
				widgetFavButton:FindFirstChildOfClass("ImageLabel").ImageColor3 = Color3.fromHex("#7a8893")
			end
		end
	end
end

updatePlayPauseButton = function()
	if isPlaying then
		playPauseButton.Image = "rbxassetid://PAUSE_ICON_ID" -- Replace with pause icon
		widgetPlayPauseButton.Image = "rbxassetid://PAUSE_ICON_ID"
	else
		playPauseButton.Image = "rbxassetid://PLAY_ICON_ID" -- Replace with play icon
		widgetPlayPauseButton.Image = "rbxassetid://PLAY_ICON_ID"
	end
end

updateLoopButton = function()
	if isLooping then
		loopButton.BackgroundColor3 = Color3.fromHex("#00cf1f")
		widgetLoopButton.BackgroundColor3 = Color3.fromHex("#00cf1f")
	else
		loopButton.BackgroundColor3 = Color3.fromHex("#c5d4e2")
		widgetLoopButton.BackgroundColor3 = Color3.fromHex("#c5d4e2")
	end
end

updateQueueDisplay = function()
	-- Clear existing queue items
	for _, child in ipairs(queueScroll:GetChildren()) do
		if child:IsA("Frame") and child.Name == "MusicCard" and child ~= musicCardTemplate then
			child:Destroy()
		end
	end

	if #queue == 0 then
		-- Show empty message if needed
	else
		for i, song in ipairs(queue) do
			local queueCard = musicCardTemplate:Clone()
			queueCard.Visible = true
			queueCard.Name = "MusicCard"
			queueCard.LayoutOrder = i

			local queueTrackInfo = queueCard:FindFirstChild("TrackInfo")
			if queueTrackInfo then
				local trackTitle = queueTrackInfo:FindFirstChild("TrackTitle")
				if trackTitle then
					trackTitle.Text = song.Name
				end

				local playlist = queueTrackInfo:FindFirstChild("Playlist")
				if playlist then
					for pName, songs in pairs(playlists) do
						if table.find(songs, song) then
							playlist.Text = pName
							break
						end
					end
				end
			end

			local queueFavButton = queueCard:FindFirstChild("FavoriteButton")
			if queueFavButton then
				local isFav = isFavorite(song)
				queueFavButton.BackgroundColor3 = isFav and Color3.fromHex("#e20553") or Color3.fromHex("#c5d4e2")
				if queueFavButton:FindFirstChildOfClass("ImageLabel") then
					queueFavButton:FindFirstChildOfClass("ImageLabel").ImageColor3 = isFav and Color3.fromHex("#ffffff") or Color3.fromHex("#7a8893")
				end

				queueFavButton.MouseButton1Click:Connect(function()
					toggleFavorite(song)
				end)
			end

			local queuePlayButton = queueCard:FindFirstChild("PlayPauseButton")
			if queuePlayButton then
				queuePlayButton.MouseButton1Click:Connect(function()
					table.remove(queue, i)
					playSong(song, false)
					updateQueueDisplay()
				end)
			end

			queueCard.Parent = queueScroll
		end
	end

	queueScroll.CanvasSize = UDim2.new(0, 0, 0, queueScroll.UIListLayout and queueScroll.UIListLayout.AbsoluteContentSize.Y or 0)
end

playSong = function(sound, fromQueue)
	if currentSound then
		currentSound:Stop()
	end

	currentSound = sound
	currentSound.Volume = currentVolume
	currentSound:Play()
	isPlaying = true

	songNameLabel.Text = sound.Name
	widgetSongName.Text = sound.Name

	if currentPlaylist then
		playlistNameLabel.Text = currentPlaylist
		widgetPlaylistName.Text = currentPlaylist
	else
		playlistNameLabel.Text = "All Songs"
		widgetPlaylistName.Text = "All Songs"
	end

	updatePlayPauseButton()
	updateFavoriteButton()
	updateQueueDisplay()

	if myLibraryPanel.Visible then
		updateLibraryContent()
	end

	if fromQueue then
		table.remove(queue, 1)
		updateQueueDisplay()
	end
end

playNextSong = function()
	if #queue > 0 then
		playSong(queue[1], true)
	elseif currentPlaylist and playlists[currentPlaylist] then
		local songs = playlists[currentPlaylist]
		currentIndex = currentIndex + 1
		if currentIndex > #songs then
			currentIndex = 1
		end
		playSong(songs[currentIndex], false)
	elseif #allSongs > 0 then
		currentIndex = currentIndex + 1
		if currentIndex > #allSongs then
			currentIndex = 1
		end
		playSong(allSongs[currentIndex], false)
	end
end

playPreviousSong = function()
	if currentPlaylist and playlists[currentPlaylist] then
		local songs = playlists[currentPlaylist]
		currentIndex = currentIndex - 1
		if currentIndex < 1 then
			currentIndex = #songs
		end
		playSong(songs[currentIndex], false)
	elseif #allSongs > 0 then
		currentIndex = currentIndex - 1
		if currentIndex < 1 then
			currentIndex = #allSongs
		end
		playSong(allSongs[currentIndex], false)
	end
end

local function createMusicCard(sound, parent)
	local card = musicCardTemplate:Clone()
	card.Visible = true
	card.Name = "MusicCard"

	local cardTrackInfo = card:FindFirstChild("TrackInfo")
	if cardTrackInfo then
		local trackTitle = cardTrackInfo:FindFirstChild("TrackTitle")
		if trackTitle then
			trackTitle.Text = sound.Name
		end

		local playlist = cardTrackInfo:FindFirstChild("Playlist")
		if playlist then
			for pName, songs in pairs(playlists) do
				if table.find(songs, sound) then
					playlist.Text = pName
					break
				end
			end
		end
	end

	local cardFavButton = card:FindFirstChild("FavoriteButton")
	if cardFavButton then
		local isFav = isFavorite(sound)
		cardFavButton.BackgroundColor3 = isFav and Color3.fromHex("#e20553") or Color3.fromHex("#c5d4e2")
		if cardFavButton:FindFirstChildOfClass("ImageLabel") then
			cardFavButton:FindFirstChildOfClass("ImageLabel").ImageColor3 = isFav and Color3.fromHex("#ffffff") or Color3.fromHex("#7a8893")
		end

		cardFavButton.MouseButton1Click:Connect(function()
			toggleFavorite(sound)
			updateLibraryContent()
		end)
	end

	local cardPlayButton = card:FindFirstChild("PlayPauseButton")
	if cardPlayButton then
		local isCurrentlyPlaying = (currentSound == sound and isPlaying)
		cardPlayButton.BackgroundColor3 = isCurrentlyPlaying and Color3.fromHex("#00cf1f") or Color3.fromHex("#c5d4e2")
		if cardPlayButton:FindFirstChildOfClass("ImageLabel") then
			cardPlayButton:FindFirstChildOfClass("ImageLabel").ImageColor3 = isCurrentlyPlaying and Color3.fromHex("#ffffff") or Color3.fromHex("#7a8893")
		end

		cardPlayButton.MouseButton1Click:Connect(function()
			if currentSound == sound and isPlaying then
				currentSound:Pause()
				isPlaying = false
				updatePlayPauseButton()
				updateLibraryContent()
			else
				for i, s in ipairs(allSongs) do
					if s == sound then
						currentIndex = i
						break
					end
				end
				playSong(sound, false)
			end
		end)
	end

	card.Parent = parent
	return card
end

local function loadPlaylistPopup(playlistName)
	-- Clear existing songs
	for _, child in ipairs(popupMusicList:GetChildren()) do
		if child:IsA("Frame") and child.Name == "MusicCard" then
			child:Destroy()
		end
	end

	-- Set playlist title
	if popupPlaylistTitle then
		popupPlaylistTitle.Text = playlistName
	end

	-- Load songs from specific playlist
	local songs = playlists[playlistName]
	if songs then
		for _, sound in ipairs(songs) do
			createMusicCard(sound, popupMusicList)
		end
	end

	popupMusicList.CanvasSize = UDim2.new(0, 0, 0, popupMusicList.UIListLayout and popupMusicList.UIListLayout.AbsoluteContentSize.Y or 0)
end

updateLibraryContent = function()
	if currentTab == "all" then
		for _, child in ipairs(allMusicList:GetChildren()) do
			if child:IsA("Frame") and child ~= musicCardTemplate then
				child:Destroy()
			end
		end

		for _, sound in ipairs(allSongs) do
			createMusicCard(sound, allMusicList)
		end

		allMusicList.CanvasSize = UDim2.new(0, 0, 0, allMusicList.UIListLayout and allMusicList.UIListLayout.AbsoluteContentSize.Y or 0)

	elseif currentTab == "favorites" then
		for _, child in ipairs(favoritesMusicList:GetChildren()) do
			if child:IsA("Frame") and child.Name == "MusicCard" then
				child:Destroy()
			end
		end

		for _, sound in ipairs(favorites) do
			createMusicCard(sound, favoritesMusicList)
		end

		favoritesMusicList.CanvasSize = UDim2.new(0, 0, 0, favoritesMusicList.UIListLayout and favoritesMusicList.UIListLayout.AbsoluteContentSize.Y or 0)

	elseif currentTab == "playlists" then
		for _, child in ipairs(playlistScroll:GetChildren()) do
			if child:IsA("Frame") and child ~= playlistCardTemplate then
				child:Destroy()
			end
		end

		for playlistName, songs in pairs(playlists) do
			local playlistCard = playlistCardTemplate:Clone()
			playlistCard.Visible = true
			playlistCard.Name = playlistName

			local infoPanel = playlistCard:FindFirstChild("InfoPanel")
			if infoPanel then
				local playlistInfoPanel = infoPanel:FindFirstChild("PlaylistInfoPanel")
				if playlistInfoPanel then
					local playingText = playlistInfoPanel:FindFirstChild("PlayingText")
					if playingText then
						local isPlayingFromThisPlaylist = (currentPlaylist == playlistName)
						playingText.Visible = isPlayingFromThisPlaylist
					end

					local playlistNameAndSongs = playlistInfoPanel:FindFirstChild("PlaylistNameAndSongs")
					if playlistNameAndSongs then
						local pName = playlistNameAndSongs:FindFirstChild("PlaylistName")
						if pName then
							pName.Text = playlistName
						end

						local totalSongs = playlistNameAndSongs:FindFirstChild("TotalSongs")
						if totalSongs then
							totalSongs.Text = #songs .. " songs"
						end
					end
				end

				local openPlaylistButton = infoPanel:FindFirstChild("OpenPlaylistButton")
				if openPlaylistButton then
					openPlaylistButton.MouseButton1Click:Connect(function()
						loadPlaylistPopup(playlistName) -- Pass playlist name ke fungsi
						playlistPopupPanel.Visible = true
						myLibraryPanel.Visible = false
					end)
				end

			end

			playlistCard.Parent = playlistScroll
		end

		playlistScroll.CanvasSize = UDim2.new(0, 0, 0, playlistScroll.UIListLayout and playlistScroll.UIListLayout.AbsoluteContentSize.Y or 0)
	end
end


-- ==================== BUTTON CONNECTIONS ====================
-- Main Panel Buttons
openLibraryButton.MouseButton1Click:Connect(function()
	myLibraryPanel.Visible = true
	mainPanel.Visible = false
	updateLibraryContent()
end)

playPauseButton.MouseButton1Click:Connect(function()
	volumePanel.Visible = false
	if currentSound then
		if isPlaying then
			currentSound:Pause()
			isPlaying = false
		else
			currentSound:Resume()
			isPlaying = true
		end
		updatePlayPauseButton()
	end
end)

nextButton.MouseButton1Click:Connect(function()
	volumePanel.Visible = false
	playNextSong()
end)

prevButton.MouseButton1Click:Connect(function()
	volumePanel.Visible = false
	playPreviousSong()
end)

loopButton.MouseButton1Click:Connect(function()
	volumePanel.Visible = false
	isLooping = not isLooping
	if currentSound then
		currentSound.Looped = isLooping
	end
	updateLoopButton()
end)

volumeButton.MouseButton1Click:Connect(function()
	volumePanel.Visible = not volumePanel.Visible
end)

favButton.MouseButton1Click:Connect(function()
	if currentSound then
		toggleFavorite(currentSound)
	end
end)

-- Volume controls
volumeAddButton.MouseButton1Click:Connect(function()
	currentVolume = math.min(1, currentVolume + 0.1)
	volumeFillBar.Size = UDim2.new(currentVolume, 0, 1, 0)
	volumeFillCircle.Position = UDim2.new(currentVolume, 0, 0.5, 0)
	if currentSound then
		currentSound.Volume = currentVolume
	end
end)

volumeMinButton.MouseButton1Click:Connect(function()
	currentVolume = math.max(0, currentVolume - 0.1)
	volumeFillBar.Size = UDim2.new(currentVolume, 0, 1, 0)
	volumeFillCircle.Position = UDim2.new(currentVolume, 0, 0.5, 0)
	if currentSound then
		currentSound.Volume = currentVolume
	end
end)

-- Widget Panel Buttons
widgetPlayPauseButton.MouseButton1Click:Connect(function()
	widgetVolumePanel.Visible = false
	if currentSound then
		if isPlaying then
			currentSound:Pause()
			isPlaying = false
		else
			currentSound:Resume()
			isPlaying = true
		end
		updatePlayPauseButton()
	end
end)

widgetNextButton.MouseButton1Click:Connect(function()
	widgetVolumePanel.Visible = false
	playNextSong()
end)

widgetPrevButton.MouseButton1Click:Connect(function()
	widgetVolumePanel.Visible = false
	playPreviousSong()
end)

widgetLoopButton.MouseButton1Click:Connect(function()
	widgetVolumePanel.Visible = false
	isLooping = not isLooping
	if currentSound then
		currentSound.Looped = isLooping
	end
	updateLoopButton()
end)

widgetVolumeButton.MouseButton1Click:Connect(function()
	widgetVolumePanel.Visible = not widgetVolumePanel.Visible
end)

widgetFavButton.MouseButton1Click:Connect(function()
	if currentSound then
		toggleFavorite(currentSound)
	end
end)

-- Widget volume controls
widgetVolumeAddButton.MouseButton1Click:Connect(function()
	currentVolume = math.min(1, currentVolume + 0.1)
	widgetVolumeFillBar.Size = UDim2.new(currentVolume, 0, 1, 0)
	widgetVolumeFillCircle.Position = UDim2.new(currentVolume, 0, 0.5, 0)
	volumeFillBar.Size = UDim2.new(currentVolume, 0, 1, 0)
	volumeFillCircle.Position = UDim2.new(currentVolume, 0, 0.5, 0)
	if currentSound then
		currentSound.Volume = currentVolume
	end
end)

widgetVolumeMinButton.MouseButton1Click:Connect(function()
	currentVolume = math.max(0, currentVolume - 0.1)
	widgetVolumeFillBar.Size = UDim2.new(currentVolume, 0, 1, 0)
	widgetVolumeFillCircle.Position = UDim2.new(currentVolume, 0, 0.5, 0)
	volumeFillBar.Size = UDim2.new(currentVolume, 0, 1, 0)
	volumeFillCircle.Position = UDim2.new(currentVolume, 0, 0.5, 0)
	if currentSound then
		currentSound.Volume = currentVolume
	end
end)

-- Library Category Buttons
allButton.MouseButton1Click:Connect(function()
	currentTab = "all"
	allPanel.Visible = true
	favoritesPanel.Visible = false
	playlistPanel.Visible = false
	updateLibraryContent()
end)

favoritesButton.MouseButton1Click:Connect(function()
	currentTab = "favorites"
	allPanel.Visible = false
	favoritesPanel.Visible = true
	playlistPanel.Visible = false
	updateLibraryContent()
end)

playlistButton.MouseButton1Click:Connect(function()
	currentTab = "playlists"
	allPanel.Visible = false
	favoritesPanel.Visible = false
	playlistPanel.Visible = true
	updateLibraryContent()
end)

-- Playlist Popup Buttons
popupCloseButton.MouseButton1Click:Connect(function()
	playlistPopupPanel.Visible = false
	mainPanel.Visible = true
end)

popupBackButton.MouseButton1Click:Connect(function()
	playlistPopupPanel.Visible = false
	myLibraryPanel.Visible = true
end)

-- ==================== PROGRESS BAR UPDATE ====================
RunService.RenderStepped:Connect(function()
	if currentSound and currentSound.IsPlaying then
		if not isDraggingProgress then
			local progress = currentSound.TimePosition / currentSound.TimeLength
			if timeline:FindFirstChild("Slider") then
				local timelineSlider = timeline:FindFirstChild("Slider")
				local timelineFillBar = timelineSlider:FindFirstChild("FillBar")
				local timelineFillCircle = timelineSlider:FindFirstChild("FillCircle")

				if timelineFillBar then
					timelineFillBar.Size = UDim2.new(progress, 0, 1, 0)
				end
				if timelineFillCircle then
					timelineFillCircle.Position = UDim2.new(progress, 0, 0.5, 0)
				end
			end

			widgetFillBar.Size = UDim2.new(progress, 0, 1, 0)
			widgetFillCircle.Position = UDim2.new(progress, 0, 0.5, 0)
			widgetCurrentTime.Text = formatTime(currentSound.TimePosition)
			widgetRemainingTime.Text = formatTime(currentSound.TimeLength - currentSound.TimePosition)
		end

		if currentSound.TimePosition >= currentSound.TimeLength - 0.1 then
			if isLooping then
				currentSound:Play()
			else
				playNextSong()
			end
		end
	end
end)

-- ==================== INITIALIZE ====================
loadPlaylists()
loadFavorites()

-- Auto-play first song
task.wait(2)
if #allSongs > 0 and not autoPlayStarted then
	autoPlayStarted = true
	playSong(allSongs[1], false)
end

print("✅ [MUSIC PLAYER] System fully loaded and ready!")
