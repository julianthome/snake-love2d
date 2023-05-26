function love.load()
    -- load images
    apple_img = love.graphics.newImage("apple.png")
    snakehead_img = {
        down = love.graphics.newImage("snakehead_down.png"),
        up = love.graphics.newImage("snakehead_up.png"),
        left = love.graphics.newImage("snakehead_left.png"),
        right = love.graphics.newImage("snakehead_right.png")
    }
    font = love.graphics.newFont(20)
    love.graphics.setFont(font)

    cell_width = 32
    state = {running = true}
    area = {width = 800, height = 800}
    board = {
        cell_width = cell_width,
        cellsxy = {},
        x_dim = area.width / cell_width,
        y_dim = area.height / cell_width
    }
    for x = 0, board.x_dim do
        board.cellsxy[x] = {}
        for y = 0, board.y_dim do
            board.cellsxy[x][y] = {
                pos_x = x * board.cell_width,
                pos_y = y * board.cell_width
            }
        end
    end
    snake = {
        length = 1,
        clock = 0,
        dir = "r",
        img = snakehead_img.right,
        segments = {
            -- this is the head
            random_pos()
        }
    }
    apple = random_pos()
    eat_sound = love.audio.newSource("eat_apple.ogg", "static") 
    background_music = love.audio.newSource("background_music.ogg", "stream")

    love.window.setMode(area.width, area.height)
end

function drawgrid()
    love.graphics.setColor(1, 0.65, 0.41, 0.2)
    love.graphics.setLineWidth(1)
    for x = 0, board.x_dim do
        for y = 0, board.y_dim do
            local cellxy = board.cellsxy[x][y]
            love.graphics.rectangle("line", cellxy.pos_x, cellxy.pos_y,
                                    board.cell_width, board.cell_width)
        end
    end
end

function random_pos()
    return {
        pos_x = love.math.random(0, board.x_dim-1),
        pos_y = love.math.random(0, board.y_dim-1)
    }
end

function print_game_over()
    local text = "Game Over! Please hit space to start a new game"
    local text_width, text_height = font:getWidth(text), font:getHeight()
    local win_width, win_height = love.graphics.getWidth(),
                                  love.graphics.getHeight()
    love.graphics.print(text, win_width / 2 - text_width / 2,
                        win_height / 2 - text_height / 2)
end

function love.draw()
    if not (state.running) then
        print_game_over()
        return
    end

    drawgrid()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print('points: ' .. tostring(snake.length - 1))

    for i, segment in pairs(snake.segments) do
        coords = board.cellsxy[segment.pos_x][segment.pos_y]
        if i == 1 then
            love.graphics.draw(snake.img, coords.pos_x, coords.pos_y, 0,
                               board.cell_width / snake.img:getWidth(),
                               board.cell_width / snake.img:getHeight(), 0, 0)
        else
            love.graphics.setColor(1, 1, 1, 0.3 + 1 / i)
            local offset = 0.15 * board.cell_width
            love.graphics.rectangle("fill", offset + coords.pos_x,
                                    offset + coords.pos_y,
                                    0.7 * board.cell_width,
                                    0.7 * board.cell_width, 3)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    local coords = board.cellsxy[apple.pos_x][apple.pos_y]
    love.graphics.draw(apple_img, coords.pos_x, coords.pos_y, 0,
                       board.cell_width / apple_img:getWidth(),
                       board.cell_width / apple_img:getHeight(), 0, 0)
end

function update_pos(dir, segment)
    if dir == "u" then
        segment.pos_y, snake.img = segment.pos_y - 1, snakehead_img.up
    elseif dir == "d" then
        segment.pos_y, snake.img = segment.pos_y + 1, snakehead_img.down
    elseif dir == "l" then
        segment.pos_x, snake.img = segment.pos_x - 1, snakehead_img.left
    elseif dir == "r" then
        segment.pos_x, snake.img = segment.pos_x + 1, snakehead_img.right
    end

    if segment.pos_y < 0 then
        segment.pos_y = board.x_dim
    elseif segment.pos_y > board.y_dim then
        segment.pos_y = 1
    end

    if segment.pos_x < 0 then
        segment.pos_x = board.x_dim
    elseif segment.pos_x > board.x_dim then
        segment.pos_x = 1
    end
end

function collision(segment, obstacle)
    return segment.pos_x == obstacle.pos_x and segment.pos_y == obstacle.pos_y
end

function running()
    for i, segment in ipairs(snake.segments) do
        if i == 1 then
            local head = segment
        elseif collision(head, segment) then
            return false
        end
    end
    return true
end

function love.update(dt)
    state.running = running()

    if not (state.running) then
        background_music:stop( )
        return
    end

    if not background_music:isPlaying( ) then
		love.audio.play( background_music )
	end

    snake.clock = snake.clock + dt
    if snake.clock < 0.15 then return end

    snake.clock = 0

    local prev = copy(snake.segments[1])
    for i, segment in ipairs(snake.segments) do
        swap(segment, prev)
        if i == 1 then
            update_pos(snake.dir, segment, board.cell_diameter)
        end
    end

    head = snake.segments[1]
    if collision(head, apple) then
        snake.length = snake.length + 1
        snake.segments[snake.length] = prev
        eat_sound:stop()
        eat_sound:play()
        apple = random_pos()
    end
end

function copy(a) return {pos_x = a.pos_x, pos_y = a.pos_y} end

function swap(a, b)
    tmp_x, tmp_y = a.pos_x, a.pos_y
    a.pos_x, a.pos_y = b.pos_x, b.pos_y
    b.pos_x, b.pos_y = tmp_x, tmp_y
end

function love.keypressed(key)
    if key == 'q' then love.event.quit() end

    if state.running == true then
        if key == "up" then
            snake.dir = "u"
        elseif key == "down" then
            snake.dir = "d"
        elseif key == "right" then
            snake.dir = "r"
        elseif key == "left" then
            snake.dir = "l"
        end
        return
    end
    if key == "space" then love.load() end
end
