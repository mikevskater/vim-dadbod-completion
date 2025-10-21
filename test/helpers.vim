" ==============================================================================
" Test Helper Functions
" ==============================================================================

" Setup test database connections
function! SetupTestDbs() abort
  " Create test database connections
  let g:dbs = {
        \ 'test_db': 'sqlite:test.db',
        \ 'test_server': 'sqlserver://localhost'
        \ }

  " Enable IntelliSense for testing
  let g:db_ui_enable_intellisense = 1
endfunction

" Cleanup test environment
function! Cleanup() abort
  " Close all buffers
  silent! %bwipeout!

  " Clear databases
  unlet! g:dbs

  " Clear test variables
  unlet! g:vim_dadbod_completion_test_mode
  unlet! g:db_ui_enable_intellisense
endfunction

" Create a mock database context for testing
function! CreateMockDbContext(db_key_name) abort
  let b:dbui_db_key_name = a:db_key_name
  let b:db = 'sqlite:test.db'
endfunction

" Create a mock completion cache
function! CreateMockCompletionCache(db_key_name) abort
  if !exists('*db_ui#completion#init_cache')
    return
  endif

  call db_ui#completion#init_cache(a:db_key_name)
endfunction

" Mock table data
function! GetMockTables() abort
  return [
        \ {'name': 'Users', 'type': 'table', 'schema': 'dbo'},
        \ {'name': 'Orders', 'type': 'table', 'schema': 'dbo'},
        \ {'name': 'Products', 'type': 'table', 'schema': 'dbo'}
        \ ]
endfunction

" Mock column data
function! GetMockColumns(table_name) abort
  if a:table_name ==# 'Users'
    return [
          \ {'name': 'user_id', 'data_type': 'INT', 'nullable': 0, 'is_pk': 1, 'is_fk': 0},
          \ {'name': 'username', 'data_type': 'VARCHAR(50)', 'nullable': 0, 'is_pk': 0, 'is_fk': 0},
          \ {'name': 'email', 'data_type': 'VARCHAR(255)', 'nullable': 1, 'is_pk': 0, 'is_fk': 0}
          \ ]
  elseif a:table_name ==# 'Orders'
    return [
          \ {'name': 'order_id', 'data_type': 'INT', 'nullable': 0, 'is_pk': 1, 'is_fk': 0},
          \ {'name': 'user_id', 'data_type': 'INT', 'nullable': 0, 'is_pk': 0, 'is_fk': 1},
          \ {'name': 'total', 'data_type': 'DECIMAL(10,2)', 'nullable': 0, 'is_pk': 0, 'is_fk': 0}
          \ ]
  else
    return []
  endif
endfunction

" Mock view data
function! GetMockViews() abort
  return [
        \ {'name': 'UserOrders', 'type': 'view', 'schema': 'dbo'},
        \ {'name': 'ActiveUsers', 'type': 'view', 'schema': 'dbo'}
        \ ]
endfunction

" Mock procedure data
function! GetMockProcedures() abort
  return [
        \ {'name': 'sp_GetUsers', 'type': 'procedure'},
        \ {'name': 'sp_CreateOrder', 'type': 'procedure'}
        \ ]
endfunction

" Mock function data
function! GetMockFunctions() abort
  return [
        \ {'name': 'fn_CalculateTotal', 'type': 'function'},
        \ {'name': 'fn_GetUserName', 'type': 'function'}
        \ ]
endfunction

" Mock schema data
function! GetMockSchemas() abort
  return ['dbo', 'sales', 'hr']
endfunction

" Mock database data
function! GetMockDatabases() abort
  return ['master', 'MyDB', 'TestDB']
endfunction
