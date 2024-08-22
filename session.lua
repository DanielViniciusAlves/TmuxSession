function Get_options()
    return {
        "-new",
        "-load",
        "-stop",
        "-remove",
        "-create",
    }
end

local function replace_slashes(input)
    input = input:gsub("[%s\t]", "")
    input = input:gsub("/", "-")
    input = input:sub(1, 1) == "-" and input:sub(2) or input
    input = input:sub(-1, -1) == "-" and input:sub(1, -2) or input

    return input
end

local function new_session()
    local response = io.popen("find ~/ -type d -print | fzf")
    if response == nil then
        return
    end

    local directory = response:read("*a")

    local session_name = replace_slashes(directory)
    if os.getenv("TMUX") then
        os.execute("tmux new -s " .. session_name .. " -d -c " .. directory)
        os.execute("tmux switch-client -t " .. session_name)
    else
        os.execute("tmux new -A -s " .. session_name .. " -c " .. directory)
    end
end

local function create_session()
    local response = io.popen("find ~/ -type d -print | fzf")
    if response == nil then
        return
    end

    local directory = response:read("*a")
    if directory == "" then
        return
    end

    local session_name = replace_slashes(directory)
    directory = directory:gsub("/", "\\/")
    directory = directory:gsub("%s+", "")

    os.execute("cp ~/.config/tmuxinator/template.yml ~/.config/tmuxinator/" .. session_name .. ".yml")
    os.execute("sed -i 's/template_session/" .. session_name .. "/g' ~/.config/tmuxinator/" .. session_name .. ".yml")
    os.execute("sed -i 's/template_directory/" .. directory .. "/g' ~/.config/tmuxinator/" .. session_name .. ".yml")
    os.execute("nvim ~/.config/tmuxinator/" .. session_name .. ".yml")
    os.execute("tmuxinator start " .. session_name)
end

local function list_sessions()
    local response = io.popen("tmux list-sessions | fzf")
    if response == nil then
        return
    end

    local session_name = response:read("*a")
    if session_name == "" then
        return
    end

    return (session_name:match("^[^:]*"))
end

local function attatch_session()
    local session_name = list_sessions()
    if session_name == nil then
        return
    end

    if os.getenv("TMUX") then
        os.execute("tmux switch-client -t " .. session_name)
        return
    end

    os.execute("tmux attach -t " .. session_name)
end

local function stop_session()
    local session_name = list_sessions()
    if session_name == nil then
        return
    end

    os.execute("tmux kill-session -t " .. session_name)
end

local function remove_session()
    local cmd = [[
        tmuxinator list |
        grep -v "tmuxinator projects:" |
        sed 's/template//g' |
        grep -o '[^ ]*' |
        fzf
    ]]

    local response = io.popen(cmd)
    if response == nil then
        return
    end

    local session_name = response:read("*a")
    if session_name == "" then
        return
    end

    print(session_name)

    os.execute("tmuxinator delete " .. session_name)
    os.execute("tmux kill-session -t " .. session_name)
end

local function load_session()
    local cmd = [[
        tmuxinator list |
        grep -v "tmuxinator projects:" |
        grep -o '[^ ]*' |
        grep -v "template" |
        fzf
    ]]

    local response = io.popen(cmd)
    if response == nil then
        return
    end

    local session_name = response:read("*a")
    if session_name == "" or session_name == nil then
        return
    end

    os.execute("tmuxinator start " .. session_name)
end

if arg[1] == "-n" or arg[1] == "-new" then
    new_session()
elseif arg[1] == "-l" or arg[1] == "-load" then
    load_session()
elseif arg[1] == "-s" or arg[1] == "-stop" then
    stop_session()
elseif arg[1] == "-rm" or arg[1] == "-remove" then
    remove_session()
elseif arg[1] == "-c" or arg[1] == "-create" then
    create_session()
elseif arg[1] == "--autocomplete" then
    local options = Get_options()
    for _, option in ipairs(options) do
        print(option)
    end
    os.exit(0)
elseif arg[1] == "-help" or arg[1] == "-h" then
    print("Usage: session.lua [OPTION]")
    print("Options:")
    print("  -new, -n\t\tCreate a new session")
    print("  -load, -l\t\tLoad a session from tmuxinator")
    print("  -stop, -s\t\tStop a session that is running")
    print("  -remove, -rm\t\tDelete a session from tmuxinator and stop it")
    print("  -create, -c\t\tCreate a tmuxinator session")
    os.exit(0)
else
    attatch_session()
end
