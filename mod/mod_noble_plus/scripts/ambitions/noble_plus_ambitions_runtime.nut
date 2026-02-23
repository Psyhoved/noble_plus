// =============================================================================
// noble_plus_ambitions_runtime — runtime реестр амбиций Noble Plus
// =============================================================================

if (!("NoblePlus" in getroottable()))
{
    ::NoblePlus <- {};
}

::NoblePlus.Ambitions <- {
    m = {
        IsInitialized = false,
        SpecsByID = {},
        SetsByID = {},
        OrderedSets = []
    },

    function init()
    {
        if (this.m.IsInitialized) return;
        if (!("AmbitionsConfig" in ::NoblePlus))
        {
            ::logError("[NoblePlus][Ambitions] Config missing: ::NoblePlus.AmbitionsConfig");
            return;
        }

        local cfg = ::NoblePlus.AmbitionsConfig;
        local hasErrors = false;
        local cfgVersion = ("meta" in cfg && "config_version" in cfg.meta) ? cfg.meta.config_version : -1;
        local runtimeVersion = ("RuntimeSchemaVersion" in ::NoblePlus) ? ::NoblePlus.RuntimeSchemaVersion : -1;
        if (cfgVersion != runtimeVersion)
        {
            hasErrors = true;
            ::logError("[NoblePlus][Ambitions] schema mismatch: config=" + cfgVersion + ", runtime=" + runtimeVersion);
        }

        this.m.SpecsByID = {};
        this.m.SetsByID = {};
        this.m.OrderedSets = [];

        foreach (set in cfg.sets)
        {
            if (!("id" in set))
            {
                hasErrors = true;
                ::logError("[NoblePlus][Ambitions] set without id");
                continue;
            }

            if (set.id in this.m.SetsByID)
            {
                hasErrors = true;
                ::logError("[NoblePlus][Ambitions] duplicate set id: " + set.id);
                continue;
            }

            this.m.SetsByID[set.id] <- set;
            this.m.OrderedSets.push(set);
        }

        this.m.OrderedSets.sort(function(a, b)
        {
            local ao = ("order" in a) ? a.order : 0;
            local bo = ("order" in b) ? b.order : 0;
            if (ao < bo) return -1;
            if (ao > bo) return 1;
            return 0;
        });

        foreach (spec in cfg.ambitions)
        {
            if (!("id" in spec))
            {
                hasErrors = true;
                ::logError("[NoblePlus][Ambitions] ambition without id");
                continue;
            }

            if (spec.id in this.m.SpecsByID)
            {
                hasErrors = true;
                ::logError("[NoblePlus][Ambitions] duplicate ambition id: " + spec.id);
                continue;
            }

            if (!("set_id" in spec) || !(spec.set_id in this.m.SetsByID))
            {
                hasErrors = true;
                ::logError("[NoblePlus][Ambitions] ambition " + spec.id + " references unknown set");
                continue;
            }

            this.m.SpecsByID[spec.id] <- spec;
        }

        this.m.IsInitialized = !hasErrors;
        if (this.m.IsInitialized)
        {
            ::logInfo("[NoblePlus][Ambitions] initialized: sets=" + this.m.OrderedSets.len() + ", ambitions=" + this.m.SpecsByID.len());
        }
    },

    function _ensureInit()
    {
        if (!this.m.IsInitialized)
        {
            this.init();
        }
        return this.m.IsInitialized;
    },

    function _isNoblePlusScenario()
    {
        if (!("World" in getroottable()) || ::World == null) return false;
        if (!("Assets" in ::World) || ::World.Assets == null) return false;
        if (::World.Assets.getOrigin() == null) return false;
        return ::World.Assets.getOrigin().getID() == ::NoblePlus.AmbitionsConfig.meta.scenario_id;
    },

    function getSpec(_id)
    {
        if (!this._ensureInit()) return null;
        if (!(_id in this.m.SpecsByID)) return null;
        return this.m.SpecsByID[_id];
    },

    function applyTexts(_ambition, _spec)
    {
        if (_ambition == null || _spec == null) return;
        if (!("texts" in _spec)) return;

        local texts = _spec.texts;
        if ("ButtonText" in texts) _ambition.m.ButtonText = texts.ButtonText;
        if ("UIText" in texts) _ambition.m.UIText = texts.UIText;
        if ("TooltipText" in texts) _ambition.m.TooltipText = texts.TooltipText;
        if ("SuccessText" in texts) _ambition.m.SuccessText = texts.SuccessText;
        if ("SuccessButtonText" in texts) _ambition.m.SuccessButtonText = texts.SuccessButtonText;
        if ("Icon" in texts) _ambition.m.Icon = texts.Icon;
    },

    function _isSetUnlocked(_set)
    {
        if (!("unlock_when" in _set)) return true;
        local rule = _set.unlock_when;

        if (!("type" in rule)) return true;
        if (rule.type == "all_flags")
        {
            foreach (flag in rule.flags)
            {
                if (!::World.Flags.has(flag)) return false;
            }
            return true;
        }

        return true;
    },

    function _isSetCompleted(_set)
    {
        if (!("complete_when" in _set)) return false;
        local rule = _set.complete_when;
        if (!("type" in rule)) return false;

        if (rule.type == "all_flags")
        {
            foreach (flag in rule.flags)
            {
                if (!::World.Flags.has(flag)) return false;
            }
            return true;
        }

        return false;
    },

    function getActiveSet()
    {
        if (!this._ensureInit()) return null;
        if (!this._isNoblePlusScenario()) return null;

        foreach (set in this.m.OrderedSets)
        {
            if ("enabled" in set && !set.enabled) continue;
            if (!this._isSetUnlocked(set)) continue;
            if (this._isSetCompleted(set)) continue;
            return set;
        }

        return null;
    },

    function isAllowed(_id)
    {
        if (!this._ensureInit()) return false;
        local spec = this.getSpec(_id);
        if (spec == null) return false;
        if ("enabled" in spec && !spec.enabled) return false;

        local set = this.m.SetsByID[spec.set_id];
        if ("enabled" in set && !set.enabled) return false;

        local activeSet = this.getActiveSet();
        if (activeSet == null) return false;
        return activeSet.id == spec.set_id;
    },

    function getScore(_id, _defaultScore = 9999)
    {
        local spec = this.getSpec(_id);
        if (spec == null) return _defaultScore;
        if ("score" in spec) return spec.score;
        return _defaultScore;
    },

    function getTarget(_id, _defaultValue)
    {
        local spec = this.getSpec(_id);
        if (spec == null) return _defaultValue;
        if (!("condition" in spec)) return _defaultValue;
        if (!("target" in spec.condition)) return _defaultValue;
        return spec.condition.target;
    },

    function getDoneFlag(_id, _defaultFlag)
    {
        local spec = this.getSpec(_id);
        if (spec == null) return _defaultFlag;
        if (!("flags" in spec)) return _defaultFlag;
        if (!("done" in spec.flags)) return _defaultFlag;
        return spec.flags.done;
    },

    function tryCompleteSet(_setID = null)
    {
        if (!this._ensureInit()) return;
        if (!this._isNoblePlusScenario()) return;

        local set = null;
        if (_setID != null && (_setID in this.m.SetsByID))
        {
            set = this.m.SetsByID[_setID];
        }
        else
        {
            set = this.getActiveSet();
        }

        if (set == null) return;
        if (!this._isSetCompleted(set)) return;
        if (!("on_complete" in set)) return;

        local oc = set.on_complete;
        local doneFlag = ("done_flag" in oc) ? oc.done_flag : null;
        local eventID = ("event_id" in oc) ? oc.event_id : null;

        if (doneFlag != null)
        {
            if (::World.Flags.has(doneFlag)) return;
            ::World.Flags.set(doneFlag, true);
        }

        if (eventID != null)
        {
            ::World.Events.fire(eventID);
            ::logInfo("[NoblePlus][Ambitions] set complete: " + set.id + ", event: " + eventID);
        }
    }
};
