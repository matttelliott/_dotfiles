local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local f = ls.function_node
local fmt = require('luasnip.extras.fmt').fmt

return {
  -- ============================================
  -- ZOD
  -- ============================================
  s('zod', fmt([[
const {}Schema = z.object({{
  {}: z.{}(),
}});
type {} = z.infer<typeof {}Schema>;
]], {
    i(1, 'User'),
    i(2, 'id'),
    i(3, 'string'),
    f(function(args) return args[1][1] end, { 1 }),
    f(function(args) return args[1][1] end, { 1 }),
  })),

  s('zparse', fmt([[
const result = {}Schema.safeParse({});
if (!result.success) {{
  {}
}}
const {} = result.data;
]], {
    i(1, 'User'),
    i(2, 'input'),
    i(3, 'return failure(result.error);'),
    i(4, 'data'),
  })),

  -- ============================================
  -- TYPE GUARDS
  -- ============================================
  s('guard', fmt([[
function is{}(value: unknown): value is {} {{
  return {};
}}
]], {
    i(1, 'Type'),
    f(function(args) return args[1][1] end, { 1 }),
    i(2, "typeof value === 'object' && value !== null"),
  })),

  s('assert', fmt([[
function assert{}(value: unknown): asserts value is {} {{
  if (!{}) {{
    throw new Error('{}');
  }}
}}
]], {
    i(1, 'Type'),
    f(function(args) return args[1][1] end, { 1 }),
    i(2, "typeof value === 'object' && value !== null"),
    i(3, 'Assertion failed'),
  })),

  -- ============================================
  -- DISCRIMINATED UNIONS
  -- ============================================
  s('union', fmt([[
type {} =
  | {{ type: '{}'; {} }}
  | {{ type: '{}'; {} }};
]], {
    i(1, 'Action'),
    i(2, 'success'),
    i(3, 'data: T'),
    i(4, 'error'),
    i(5, 'message: string'),
  })),

  s('match', fmt([[
switch ({}.type) {{
  case '{}':
    {}
    break;
  case '{}':
    {}
    break;
  default:
    const _exhaustive: never = {};
    throw new Error(`Unhandled: ${{_exhaustive}}`);
}}
]], {
    i(1, 'action'),
    i(2, 'success'),
    i(3, 'return action.data;'),
    i(4, 'error'),
    i(5, 'throw new Error(action.message);'),
    f(function(args) return args[1][1] end, { 1 }),
  })),

  -- ============================================
  -- ASYNC PATTERNS
  -- ============================================
  s('afn', fmt([[
async function {}({}): Promise<{}> {{
  {}
}}
]], {
    i(1, 'name'),
    i(2),
    i(3, 'void'),
    i(0),
  })),

  s('try', fmt([[
try {{
  {}
}} catch (e) {{
  if (e instanceof Error) {{
    {}
  }}
  throw e;
}}
]], {
    i(1),
    i(2, 'console.error(e.message);'),
  })),

  s('fetch', fmt([[
const response = await fetch({});
if (!response.ok) {{
  throw new Error(`${{response.status}}: ${{response.statusText}}`);
}}
const {}: {} = await response.json();
]], {
    i(1, 'url'),
    i(2, 'data'),
    i(3, 'T'),
  })),

  -- ============================================
  -- CONST OBJECTS (enum alternative)
  -- ============================================
  s('const', fmt([[
const {} = {{
  {}: '{}',
}} as const;
type {} = typeof {}[keyof typeof {}];
]], {
    i(1, 'Status'),
    i(2, 'Active'),
    i(3, 'active'),
    f(function(args) return args[1][1] end, { 1 }),
    f(function(args) return args[1][1] end, { 1 }),
    f(function(args) return args[1][1] end, { 1 }),
  })),

  -- ============================================
  -- FUNCTION TYPES
  -- ============================================
  s('fn', fmt([[
const {} = ({}): {} => {{
  {}
}};
]], {
    i(1, 'name'),
    i(2),
    i(3, 'void'),
    i(0),
  })),

  s('gfn', fmt([[
function {}<{}>({}): {} {{
  {}
}}
]], {
    i(1, 'name'),
    i(2, 'T'),
    i(3, 'value: T'),
    i(4, 'T'),
    i(0, 'return value;'),
  })),

  -- ============================================
  -- INTERFACE / TYPE
  -- ============================================
  s('iface', fmt([[
interface {} {{
  {}: {};
}}
]], {
    i(1, 'Name'),
    i(2, 'prop'),
    i(3, 'string'),
  })),

  s('type', fmt([[
type {} = {{
  {}: {};
}};
]], {
    i(1, 'Name'),
    i(2, 'prop'),
    i(3, 'string'),
  })),

  -- ============================================
  -- TESTS
  -- ============================================
  s('desc', fmt([[
describe('{}', () => {{
  {}
}});
]], {
    i(1, 'module'),
    i(0),
  })),

  s('it', fmt([[
it('{}', {} () => {{
  {}
}});
]], {
    i(1, 'should do something'),
    c(2, { t('async'), t('') }),
    i(0),
  })),

  s('expect', fmt([[
expect({}).{}({});
]], {
    i(1, 'value'),
    c(2, { t('toBe'), t('toEqual'), t('toThrow'), t('toBeDefined'), t('toHaveBeenCalledWith') }),
    i(3),
  })),

  -- ============================================
  -- REACT (if you use it)
  -- ============================================
  s('ustate', fmt([[
const [{}, set{}] = useState<{}>({});
]], {
    i(1, 'value'),
    f(function(args)
      local s = args[1][1]
      return s:sub(1,1):upper() .. s:sub(2)
    end, { 1 }),
    i(2, 'string'),
    i(3, "''"),
  })),

  s('ueffect', fmt([[
useEffect(() => {{
  {}
  return () => {{
    {}
  }};
}}, [{}]);
]], {
    i(1),
    i(2, '// cleanup'),
    i(3),
  })),

  s('ucb', fmt([[
const {} = useCallback(({}) => {{
  {}
}}, [{}]);
]], {
    i(1, 'handler'),
    i(2),
    i(3),
    i(4),
  })),

  s('umemo', fmt([[
const {} = useMemo(() => {{
  return {};
}}, [{}]);
]], {
    i(1, 'value'),
    i(2),
    i(3),
  })),

  -- ============================================
  -- COMMON PATTERNS
  -- ============================================
  s('log', fmt([[
console.log('{}', {});
]], {
    i(1, 'label'),
    i(2, 'value'),
  })),

  s('todo', t('// TODO: ')),

  s('fixme', t('// FIXME: ')),
}
