function dist(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

function vec(x, y) return {x = x, y = y} end

function vec_dot(a, b) return a.x * b.x + a.y * b.y end

function vec_angle(a, b)
    return math.acos(vec_dot(a, b) / (vec_len(a) * vec_len(b)))
end

function vec_angle_ref(a) return math.atan2(a.x, -a.y) end

function vec_len(v) return math.sqrt(v.x * v.x + v.y * v.y) end

function vec_norm(v) return vec(v.x / vec_len(v), v.y / vec_len(v)) end

function vec_sub(a, b) return {x = a.x - b.x, y = a.y - b.y} end

function vec_add(a, b) return {x = a.x + b.x, y = a.y + b.y} end

function vec_scale(v, s) return vec(v.x * s, v.y * s) end

function vec_unpack(v) return v.x, v.y end

function vec_with_x(v, x) return {x, v.y} end

function vec_with_y(v, y) return {v.x, y} end

function love.load()
    love.graphics.setDefaultFilter('nearest', 'nearest', 1)
    love.graphics.setLineStyle('rough')

    -- Assets
    assets = {
        ship_join = love.graphics.newImage("assets/ship-join.png"),
        ship_core = love.graphics.newImage("assets/ship-core.png"),
        ship_head = love.graphics.newImage("assets/ship-head.png"),
        ship_module = love.graphics.newImage("assets/ship-module.png"),
        bullet = love.graphics.newImage("assets/bullet.png"),
        stars = love.graphics.newImage("assets/stars.png")
    }

    assets.stars:setWrap("repeat", "repeat")

    -- Rendering 
    canvas = love.graphics.newCanvas(320, 240)
    scale = 3

    -- Game State
    player_speed = 2

    entities = {}

    player_body = {
        {pos = vec(10, 10), size = 12, core = false},
        {pos = vec(20, 20), size = 10, core = false},
        {pos = vec(30, 30), size = 16, core = true},
        {pos = vec(40, 40), size = 10, core = false},
        {pos = vec(50, 50), size = 12, core = false}
    }
end

local function player_body_direction(index)
    if index == 1 then
        return vec_norm(vec_sub(player_body[1].pos, player_body[2].pos))
    else
        return vec_norm(vec_sub(player_body[index - 1].pos,
                                player_body[index].pos))
    end
end

local function entity_spawn(e, pos)
    e.pos = pos
    table.insert(entities, e)
end

local function entity_lifetime(e, lifetime)
    e.lifetime = lifetime
    return e
end

local function entity_speed(e, speed)
    e.speed = speed
    return e;
end

local function entity_sprite(e, sprite)
    e.sprite = sprite
    return e
end

local function spaw_bullet(pos, speed)
    bullet = {}
    bullet = entity_sprite(bullet, assets.bullet)
    bullet = entity_lifetime(bullet, 2)
    bullet = entity_speed(bullet, speed)
    entity_spawn(bullet, pos)
end

function entity_physic()
    for i, v in ipairs(entities) do
        if v.pos ~= nil and v.speed ~= nil then
            v.pos = vec_add(v.pos, v.speed)
        end
    end
end

function love.update(dt)
    entity_physic()

    for i, curr in ipairs(player_body) do
        if i == 1 then
            local mx = 0;
            local my = 0;

            if love.keyboard.isDown("z") then my = my - 1 end
            if love.keyboard.isDown("s") then my = my + 1 end
            if love.keyboard.isDown("q") then mx = mx - 1 end
            if love.keyboard.isDown("d") then mx = mx + 1 end

            if mx ~= 0 or my ~= 0 then
                local v = vec_scale(vec_norm(vec(mx, my)), player_speed)
                curr.pos = vec_add(curr.pos, v)
            end

            if love.keyboard.isDown('space') then
                spaw_bullet(curr.pos, vec_scale(player_body_direction(1), 2))
            end
        else
            local prev = player_body[i - 1]

            if dist(prev.pos, curr.pos) > 16 then
                local v = vec_scale(vec_norm(vec_sub(prev.pos, curr.pos)),
                                    player_speed)
                curr.pos = vec_add(curr.pos, v)
            end
        end
    end
end

function draw_player()
    for i, curr in ipairs(player_body) do
        if not curr.core and i ~= 1 and i ~= #player_body then
            love.graphics.draw(assets.ship_join, curr.pos.x, curr.pos.y, 0, 1,
                               1, 16, 16)
        end
    end

    for i, curr in ipairs(player_body) do
        local rot = vec_angle_ref(player_body_direction(i));
        if i == 1 then
            love.graphics.draw(assets.ship_head, curr.pos.x, curr.pos.y, rot, 1,
                               1, 16, 16)
        elseif i == #player_body or curr.core then
            love.graphics.draw(assets.ship_module, curr.pos.x, curr.pos.y, rot,
                               1, 1, 16, 16)
        end
        if curr.core then
            love.graphics.draw(assets.ship_core, curr.pos.x, curr.pos.y, 0, 1,
                               1, 16, 16)
        end
    end
end

function entity_render()
    for i, e in ipairs(entities) do
        if e.sprite ~= nil and e.pos ~= nil then
            love.graphics.draw(e.sprite, e.pos.x, e.pos.y, 0, 1, 1,
                               e.sprite.getWidth(e.sprite) / 2,
                               e.sprite.getHeight(e.sprite) / 2)
        end
    end
end

function parallax_render()
    for i = 1, 4, 1 do
        local px = player_body[1].pos.x / (2 * i * i)
        local py = player_body[1].pos.y / (2 * i * i)
        local quad = love.graphics.newQuad(px, py, canvas:getWidth(),
                                           canvas:getHeight(), assets.stars)
        love.graphics.draw(assets.stars, quad, 0, 0, 0, 1, 1, 0, 0)
    end
end

function love.draw()
    -- Pixel Canvas Render
    love.graphics.setCanvas(canvas)
    love.graphics.clear()
    parallax_render()

    love.graphics.push()
    love.graphics.translate(-player_body[1].pos.x + (canvas:getWidth() / 2),
                            -player_body[1].pos.y + (canvas:getHeight() / 2))

    entity_render()
    draw_player()

    --[[
    for i, curr in ipairs(player_body) do
        if i == 1 then
            love.graphics.circle("fill", curr.pos.x, curr.pos.y, curr.size, 16)
        else
            love.graphics.circle("line", curr.pos.x, curr.pos.y, curr.size, 16)
            local prev = player_body[i - 1]
            
            local v = vec_sub(prev.pos, curr.pos)
            local pos = vec_add(curr.pos, v)
            
            love.graphics.setColor(1, 0, 0)
            love.graphics.line(curr.pos.x, curr.pos.y, pos.x, pos.y)
            
            love.graphics.setColor(1, 1, 1)
        end
    end
    ]]

    love.graphics.pop()

    -- Render to the final screen 
    love.graphics.setCanvas()
    love.graphics.clear()
    love.graphics.draw(canvas, 0, 0, 0, scale, scale);
end
