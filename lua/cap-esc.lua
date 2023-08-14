local M = {}
function M.setup(opts)
    opts = opts or {}
    local escGroup = vim.api.nvim_create_augroup("esc-caps", {})
    local json = ""
    local function getKeys()
        json = ""
        local job = vim.fn.jobstart('hidutil property --get "UserKeyMapping"', {
            on_stdout = function(_, data, _)
                json = json .. table.concat(data, "")
            end
        })
        vim.fn.jobwait({ job })
        json = string.gsub(json, "%(", "")
        json = string.gsub(json, "%)", "")
        json = string.gsub(json, " =", ":")
        json = string.gsub(json, ";", ",")
        json = string.gsub(json, "([A-Za-z]+)", '"%1"')
    end
    local function setKey()
        local keys = opts.keys or {
            ["0x700000029"] = "0x700000039",
            ["0x700000039"] = "0x700000029"
        }
        local newTable = {}
        for k, v in pairs(keys) do
            table.insert(newTable,
                string.format('{"HIDKeyboardModifierMappingSrc":%s,"HIDKeyboardModifierMappingDst":%s}', k, v))
        end
        if opts.merge_keys == nil and true or opts.merge_keys then
            vim.fn.jobstart([[hidutil property --set '{"UserKeyMapping":[]] ..
                table.concat(newTable, ',') .. ',' .. json .. [[]}']])
        else
            vim.fn.jobstart([[hidutil property --set '{"UserKeyMapping":[]] .. table.concat(newTable, ',') .. [[]}']])
        end
    end

    local function clearKey()
        vim.fn.jobstart([[hidutil property --set '{"UserKeyMapping":[]] .. json .. [[]}']], {
            detach = true
        })
    end

    vim.api.nvim_create_autocmd({ "VimEnter" }, {
        pattern = { "*" },
        group = escGroup,
        callback = function()
            if opts.preserve_keys == nil and true or opts.preserve_keys then
                getKeys()
            end
            setKey()
        end
    })

    vim.api.nvim_create_autocmd({ "FocusGained", "VimResume" }, {
        pattern = { "*" },
        group = escGroup,
        callback = function()
            if opts.preserve_changes then
                getKeys()
            end
            setKey()
        end
    })

    vim.api.nvim_create_autocmd({ "FocusLost", "VimLeave", "VimSuspend" }, {
        pattern = { "*" },
        group = escGroup,
        callback = clearKey
    })
end

return M
