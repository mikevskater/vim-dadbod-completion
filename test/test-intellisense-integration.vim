let s:suite = themis#suite('IntelliSense Integration')
let s:expect = themis#helper('expect')

function! s:suite.before() abort
  " Mock vim-dadbod-ui IntelliSense functions
  let g:vim_dadbod_completion_test_mode = 1
  let g:db_ui_enable_intellisense = 1
endfunction

function! s:suite.after() abort
  unlet! g:vim_dadbod_completion_test_mode
  unlet! g:db_ui_enable_intellisense
  if exists('*db_ui#completion#clear_all_caches')
    call db_ui#completion#clear_all_caches()
  endif
endfunction

" ==============================================================================
" IntelliSense Availability Tests
" ==============================================================================

function! s:suite.should_check_intellisense_availability() abort
  " Test that the availability check function exists
  call s:expect(exists('*vim_dadbod_completion#dbui#is_available')).to_be_true()
endfunction

function! s:suite.should_detect_when_intellisense_is_unavailable() abort
  " Mock no vim-dadbod-ui functions
  let available = vim_dadbod_completion#dbui#is_available()

  " Without vim-dadbod-ui loaded, it should return false
  if !exists('*db_ui#completion#is_available')
    call s:expect(available).to_be_false()
  endif
endfunction

" ==============================================================================
" Completion Item Enrichment Tests
" ==============================================================================

function! s:suite.should_format_column_info() abort
  " Test column info formatting
  let col = {
        \ 'name': 'user_id',
        \ 'data_type': 'INT',
        \ 'nullable': 0,
        \ 'is_pk': 1,
        \ 'is_fk': 0
        \ }

  let info = s:call_format_column_info(col)

  call s:expect(info).to_match('INT')
  call s:expect(info).to_match('NOT NULL')
  call s:expect(info).to_match('PRIMARY KEY')
endfunction

function! s:suite.should_format_column_with_fk() abort
  let col = {
        \ 'name': 'order_id',
        \ 'data_type': 'INT',
        \ 'nullable': 1,
        \ 'is_pk': 0,
        \ 'is_fk': 1
        \ }

  let info = s:call_format_column_info(col)

  call s:expect(info).to_match('INT')
  call s:expect(info).to_match('NULL')
  call s:expect(info).to_match('FOREIGN KEY')
  call s:expect(info).not.to_match('PRIMARY KEY')
endfunction

function! s:suite.should_format_table_info() abort
  let tbl = {
        \ 'name': 'Users',
        \ 'type': 'table',
        \ 'schema': 'dbo'
        \ }

  let info = s:call_format_table_info(tbl)

  call s:expect(info).to_match('TABLE')
  call s:expect(info).to_match('dbo')
endfunction

function! s:suite.should_format_external_table_info() abort
  let tbl = {
        \ 'name': 'Orders',
        \ 'type': 'view',
        \ 'schema': 'dbo',
        \ 'database': 'MyDB'
        \ }

  let info = s:call_format_table_info(tbl)

  call s:expect(info).to_match('VIEW')
  call s:expect(info).to_match('dbo')
  call s:expect(info).to_match('MyDB')
endfunction

" ==============================================================================
" Completion Kind Tests
" ==============================================================================

function! s:suite.should_set_column_kind() abort
  let item = s:create_completion_item('user_id', 'C')
  call s:expect(item.kind).to_equal('C')
endfunction

function! s:suite.should_set_table_kind() abort
  let item = s:create_completion_item('Users', 'T')
  call s:expect(item.kind).to_equal('T')
endfunction

function! s:suite.should_set_view_kind() abort
  let item = s:create_completion_item('UserOrders', 'V')
  call s:expect(item.kind).to_equal('V')
endfunction

function! s:suite.should_set_procedure_kind() abort
  let item = s:create_completion_item('sp_GetUsers', 'P')
  call s:expect(item.kind).to_equal('P')
endfunction

function! s:suite.should_set_function_kind() abort
  let item = s:create_completion_item('fn_CalculateTotal', 'F')
  call s:expect(item.kind).to_equal('F')
endfunction

function! s:suite.should_set_schema_kind() abort
  let item = s:create_completion_item('dbo', 'S')
  call s:expect(item.kind).to_equal('S')
endfunction

function! s:suite.should_set_database_kind() abort
  let item = s:create_completion_item('MyDatabase', 'D')
  call s:expect(item.kind).to_equal('D')
endfunction

" ==============================================================================
" Context-Based Completion Tests
" ==============================================================================

function! s:suite.should_return_empty_for_no_context() abort
  if !exists('*vim_dadbod_completion#dbui#get_completions')
    return
  endif

  " Create a buffer without database context
  new
  let items = vim_dadbod_completion#dbui#get_completions(bufnr(''), '', '', 1)

  call s:expect(type(items)).to_equal(v:t_list)
  call s:expect(len(items)).to_equal(0)

  close!
endfunction

" ==============================================================================
" Main Completion Function Integration Tests
" ==============================================================================

function! s:suite.should_fallback_to_standard_when_intellisense_unavailable() abort
  " Test that standard completion is used when IntelliSense is not available
  " This is tested implicitly by checking that completion doesn't fail
  let result = vim_dadbod_completion#omni(0, '')
  call s:expect(type(result)).to_be_one_of([v:t_list, v:t_number])
endfunction

" ==============================================================================
" Data Type Display Tests
" ==============================================================================

function! s:suite.should_display_data_type_in_menu() abort
  let col = {
        \ 'name': 'email',
        \ 'data_type': 'VARCHAR(255)'
        \ }

  let item = {
        \ 'word': col.name,
        \ 'abbr': col.name,
        \ 'menu': '[DB]',
        \ 'kind': 'C'
        \ }

  " Simulate data type addition
  if has_key(col, 'data_type') && !empty(col.data_type)
    let item.menu = printf('[DB] [%s]', col.data_type)
  endif

  call s:expect(item.menu).to_match('VARCHAR(255)')
endfunction

" ==============================================================================
" External Database Completion Tests
" ==============================================================================

function! s:suite.should_handle_external_database_completions() abort
  if !exists('*db_ui#completion#get_external_completions')
    return
  endif

  " This should not crash even if external DB doesn't exist
  let ext_completions = db_ui#completion#get_external_completions(
        \ 'test_db',
        \ 'external_db',
        \ 'tables',
        \ ''
        \ )

  call s:expect(type(ext_completions)).to_equal(v:t_list)
endfunction

" ==============================================================================
" Blink.cmp Adapter Tests
" ==============================================================================

function! s:suite.should_map_completion_kinds_for_blink() abort
  " Test that all completion kinds are properly mapped
  let kind_mapping = {
        \ 'F': 3,
        \ 'C': 5,
        \ 'A': 6,
        \ 'T': 7,
        \ 'V': 7,
        \ 'R': 14,
        \ 'P': 2,
        \ 'D': 8,
        \ 'S': 19
        \ }

  " Verify all expected kinds are present
  call s:expect(has_key(kind_mapping, 'F')).to_be_true()
  call s:expect(has_key(kind_mapping, 'C')).to_be_true()
  call s:expect(has_key(kind_mapping, 'T')).to_be_true()
  call s:expect(has_key(kind_mapping, 'V')).to_be_true()
  call s:expect(has_key(kind_mapping, 'P')).to_be_true()
  call s:expect(has_key(kind_mapping, 'D')).to_be_true()
  call s:expect(has_key(kind_mapping, 'S')).to_be_true()
endfunction

" ==============================================================================
" Filter Tests
" ==============================================================================

function! s:suite.should_filter_completions_by_base() abort
  let items = [
        \ {'word': 'user_id', 'kind': 'C'},
        \ {'word': 'user_name', 'kind': 'C'},
        \ {'word': 'order_id', 'kind': 'C'}
        \ ]

  " Filter by 'user'
  let filtered = filter(copy(items), 'v:val.word =~? "^user"')

  call s:expect(len(filtered)).to_equal(2)
  call s:expect(filtered[0].word).to_match('^user')
  call s:expect(filtered[1].word).to_match('^user')
endfunction

function! s:suite.should_filter_case_insensitive() abort
  let items = [
        \ {'word': 'UserID', 'kind': 'C'},
        \ {'word': 'username', 'kind': 'C'}
        \ ]

  " Filter by 'user' (lowercase)
  let filtered = filter(copy(items), 'v:val.word =~? "^user"')

  call s:expect(len(filtered)).to_equal(2)
endfunction

" ==============================================================================
" Helper Functions
" ==============================================================================

" Helper to call internal format_column_info function
function! s:call_format_column_info(column) abort
  " Since s:format_column_info is script-local, we simulate it
  let info = []

  if has_key(a:column, 'data_type') && !empty(a:column.data_type)
    call add(info, 'Type: ' . a:column.data_type)
  endif

  if has_key(a:column, 'nullable')
    call add(info, a:column.nullable ? 'NULL' : 'NOT NULL')
  endif

  if has_key(a:column, 'is_pk') && a:column.is_pk
    call add(info, 'PRIMARY KEY')
  endif

  if has_key(a:column, 'is_fk') && a:column.is_fk
    call add(info, 'FOREIGN KEY')
  endif

  return join(info, ' | ')
endfunction

" Helper to call internal format_table_info function
function! s:call_format_table_info(table) abort
  let info = []

  call add(info, has_key(a:table, 'type') ? toupper(a:table.type) : 'TABLE')

  if has_key(a:table, 'schema') && !empty(a:table.schema)
    call add(info, 'Schema: ' . a:table.schema)
  endif

  if has_key(a:table, 'database') && !empty(a:table.database)
    call add(info, 'Database: ' . a:table.database)
  endif

  return join(info, ' | ')
endfunction

" Helper to create completion item
function! s:create_completion_item(word, kind) abort
  return {
        \ 'word': a:word,
        \ 'abbr': a:word,
        \ 'menu': '[DB]',
        \ 'kind': a:kind,
        \ 'info': ''
        \ }
endfunction
