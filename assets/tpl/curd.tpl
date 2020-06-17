{{- $isTree := 0 }}
{{- range $j, $row := .Fields}}
	{{- if eq $row.Name "ParentId"}}
        {{- $isTree = add $isTree 1 }}
    {{- else if eq $row.Name "Sort"}}
        {{- $isTree = add $isTree 1 }}
    {{- end}}
{{- end -}}

const Table{{.StructTableName}} = "{{.TableName}}"

{{.TableComment}}
type {{.StructTableName}} struct {
{{- range $j, $item := .Fields}}
	{{$item.Name}}	   {{$item.Type}}	{{$item.FormatFields}}		{{$item.Remark}}
{{- end}}
{{- if ge $isTree 2}}
	Children   {{.StructTableName}}List         // 子节点
	Selected   bool                             // 是否处于选中状态
{{- end}}
}

{{.TableComment}} Null Entity
type {{.NullStructTableName}} struct {
{{range $j, $row := .Fields}}	{{$row.Name}}	{{$row.NullType}}		 {{$row.Remark}}
{{end}}}

func (row *{{.NullStructTableName}}) To{{.StructTableName}}() *{{.StructTableName}} {
	return &{{.StructTableName}}{
	{{- range $j, $row := .Fields}}
	{{- if eq $row.Type "float64"}}
		{{$row.Name}}:	row.{{$row.Name}}.Float64,	{{$row.Remark}}
	{{- else if eq $row.Type "float"}}
		{{$row.Name}}:	row.{{$row.Name}}.Float,	{{$row.Remark}}
	{{- else if eq $row.Type "int64"}}
		{{$row.Name}}:	row.{{$row.Name}}.Int64,	{{$row.Remark}}
	{{- else if eq $row.Type "int"}}
		{{$row.Name}}:	row.{{$row.Name}}.Int,	{{$row.Remark}}
	{{- else if eq $row.Type "time.Time"}}
		{{$row.Name}}:	ToTime(row.{{$row.Name}}),	{{$row.Remark}}
	{{- else if eq $row.Type "*Time"}}
		{{$row.Name}}:	ToTime(row.{{$row.Name}}),	{{$row.Remark}}
	{{- else}}
		{{$row.Name}}:	row.{{$row.Name}}.String,	{{$row.Remark}}
	{{- end}}
	{{- end}}
	}
}

type {{.StructTableName}}Model struct {
	DB *gorm.DB
}

var default{{.StructTableName}}	*{{.StructTableName}}Model
var mutex{{.StructTableName}} sync.Mutex

func Get{{.StructTableName}}() *{{.StructTableName}}Model{
	defer mutex{{.StructTableName}}.Unlock()
	mutex{{.StructTableName}}.Lock()
	if default{{.StructTableName}}==nil {
		var err error
		if default{{.StructTableName}}, err = New{{.StructTableName}}(); err!=nil {
			panic(fmt.Sprintf("无法连接数据库。%v", err))
		}
	}
	return default{{.StructTableName}}
}

func New{{.StructTableName}}(db ...*gorm.DB) (*{{.StructTableName}}Model, error) {
	if len(db) > 0 {
		return &{{.StructTableName}}Model{
			DB: db[0],
		}, nil
	}
	if conn, err := conf.DefaultConf.GetDb(false); err!=nil {
		return nil, err
	}else{
		return &{{.StructTableName}}Model{
			DB: conn,
		}, nil
	}
}

// 获取所有的表字段
func (m *{{.StructTableName}}Model) GetColumns() string {
	return " {{.AllFieldList}} "
}

// 获取多行数据.
func (m *{{.StructTableName}}Model) GetRows(sqlTxt string, params ...interface{}) (rowsResult []*{{.StructTableName}}, err error) {
	query, err := m.DB.DB().Query(sqlTxt, params...)
	if err != nil {
		return
	}
	defer func() {
		if err:=query.Close(); err!=nil {
			fmt.Printf("释放数据库连接失败。%v\r\n", err)
		}
	}()
	for query.Next() {
		row := {{.NullStructTableName}}{}
		err = query.Scan(
		{{range .NullFieldsInfo}}&row.{{.HumpName}},// {{.Comment}}
		{{end}})
		if nil != err {
			fmt.Printf("查询失败。%v\r\n", err)
			continue
		}
		rowsResult = append(rowsResult, row.To{{.StructTableName}}())
	}
	return
}

// 获取单行数据
func (m *{{.StructTableName}}Model) GetRow(sqlText string, params ...interface{}) (rowResult *{{.StructTableName}}, err error) {
	query := m.DB.DB().QueryRow(sqlText, params...)
	row := {{.NullStructTableName}}{}
	err = query.Scan(
	{{range .NullFieldsInfo}}&row.{{.HumpName}},// {{.Comment}}
	{{end}})
	if err==nil {
		rowResult = row.To{{.StructTableName}}()
	}
	return
}

// 更新数据
func (m *{{.StructTableName}}Model) Save(sqlTxt string, value ...interface{}) (affectCount int64, err error) {
	stmt, err := m.DB.DB().Prepare(sqlTxt)
	defer func() {
		if err:=stmt.Close(); err!=nil {
			fmt.Printf("释放数据库连接失败。%v\r\n", err)
		}
	}()
	result, err := stmt.Exec(value...)
	if err == nil {
		affectCount, err = result.RowsAffected()
	}
	return
}

// 新增信息
func (m *{{.StructTableName}}Model) Create(value *{{.StructTableName}}) error {
	const sqlText = "INSERT INTO " + Table{{.StructTableName}} + " ({{.InsertFieldList}}) VALUES ({{.InsertMark}})"
	stmt, err := m.DB.DB().Prepare(sqlText)
	if err != nil {
		return err
	}
	defer func() {
		if err:=stmt.Close(); err!=nil {
			fmt.Printf("释放数据库连接失败。%v\r\n", err)
		}
	}()
	_, err = stmt.Exec(
	{{- range .InsertInfo}}
		{{- if eq .GoType "Time" }}
			time.Time(value.{{.HumpName}}),    // {{.Comment}}
		{{- else }}
			value.{{.HumpName}},    // {{.Comment}}
		{{- end }}
	{{- end}}
	)
	if err != nil {
		return err
	}
	return nil
}

// 更新数据
func (m *{{.StructTableName}}Model) Update(value *{{.StructTableName}}) (affectCount int64, err error) {
	sqlText := "UPDATE " + Table{{.StructTableName}} + " SET {{.UpdateFieldList}} WHERE {{.PrimaryKey}} = ?"
	params := make([]interface{}, 0)
	{{range $i, $val := .UpdateListField}}params = append(params, {{$val}})
	{{end}}
	return m.Save(sqlText, params...)
}

// 查询多行数据
func (m *{{.StructTableName}}Model) All() (resList []*{{.StructTableName}}, err error) {
	sqlText := "SELECT" + m.GetColumns() + "FROM " + Table{{.StructTableName}}
	resList, err = m.GetRows(sqlText)
	return
}

// 获取单行数据
func (m *{{.StructTableName}}Model) First() (result *{{.StructTableName}}, err error) {
	sqlText := "SELECT" + m.GetColumns() + "FROM " + Table{{.StructTableName}} + " LIMIT 1"
	result, err = m.GetRow(sqlText)
	if err != nil {
		return
	}
	return
}

// 获取最后一行数据
func (m *{{.StructTableName}}Model) Last() (result *{{.StructTableName}}, err error) {
	sqlText := "SELECT" + m.GetColumns() + "FROM " + Table{{.StructTableName}} + " ORDER BY ID DESC LIMIT 1"
	result, err = m.GetRow(sqlText)
	if err != nil {
		return
	}
	return
}

// 获取行数
func (m *{{.StructTableName}}Model) Count() (count int64, err error) {
	sqlText := "SELECT COUNT(*) FROM " + Table{{.StructTableName}}
	query := m.DB.DB().QueryRow(sqlText)
	err = query.Scan(&count)
	if err != nil {
		return
	}
	return
}

// 判断是否存在
func (m *{{.StructTableName}}Model) Exists(id {{.PrimaryType}}) (b bool, err error) {
	sqlText := "SELECT COUNT(*) FROM " + Table{{.StructTableName}} + " where id = ?"
	query := m.DB.DB().QueryRow(sqlText, id)
	var count int64
	err = query.Scan(&count)
	if err != nil {
		return
	}
	if count > 0 {
		b = true
		return
	}
	return
}

// 按指定的条件查询列表
func (m *{{.StructTableName}}Model) Find(where interface{}, args ...interface{}) (resList []*{{.StructTableName}}, err error) {
	err = m.DB.Where(where, args).Order("id desc").Find(&resList).Error
	return
}

// 按指定的查询条件删除数据
func (m *{{.StructTableName}}Model) Delete(where interface{}, args ...interface{}) (int64,error) {
	db:=m.DB.Where(where, args).Delete({{.StructTableName}}{})
	return db.RowsAffected, db.Error
}

// 删除指定主键值的数据
func (m *{{.StructTableName}}Model) DeleteById(ids ...interface{}) (int64,error) {
	var db *gorm.DB
	if len(ids)==0 {
		return 0, nil
	}else if len(ids)==1 {
		db=m.DB.Table(Table{{.StructTableName}}).Where("id=?", ids[0]).Delete({{.StructTableName}}{})
	}else{
		db=m.DB.Table(Table{{.StructTableName}}).Where("id IN (?)", ids).Delete({{.StructTableName}}{})
	}
	return db.RowsAffected, db.Error
}

{{- /* 为树结构生成一些函数 */}}
{{ if ge $isTree 2}}
func (row *{{.StructTableName}}) AddChild(child *{{.StructTableName}}) {
	row.Children = append(row.Children, child)
}

func (m *{{.StructTableName}}Model) GetTree(where *{{.StructTableName}}, sort bool, checked... string) (*{{.StructTableName}}, error) {
	var resList {{.StructTableName}}List
	m.DB.Error = nil
	m.DB.Where(where).Find(&resList)
	return resList.ToTree(sort, checked...), m.DB.Error
}

type {{.StructTableName}}List []*{{.StructTableName}}

// 实现sort.Interface接口取元素数量方法
func (list {{.StructTableName}}List) Len() int {
	return len(list)
}
// 实现sort.Interface接口比较元素方法
func (list {{.StructTableName}}List) Less(i, j int) bool {
	if list[i].Sort == list[j].Sort {
		return list[i].Id < list[j].Id // 按ID升序
	}else{
		return list[i].Sort < list[j].Sort
	}
}
// 实现sort.Interface接口交换元素方法
func (list {{.StructTableName}}List) Swap(i, j int) {
	list[i], list[j] = list[j], list[i]
}
//深度排序
func (list {{.StructTableName}}List) DeepSort(){
	sort.Sort(list)
	for _, row := range list {
		if row.Children!=nil {
			row.Children.DeepSort()		//递归
		}
	}
}
func (list {{.StructTableName}}List) ToMap() map[string]*{{.StructTableName}} {
	map1 := make(map[string]*{{.StructTableName}})
	for index, row := range list {
		map1[row.Id] = list[index]
	}
	return map1
}

func (list {{.StructTableName}}List) ToTree(sort bool, checked... string) *{{.StructTableName}} {
	root:=&{{.StructTableName}}{}
	var parent *{{.StructTableName}}
	var exists bool
	var c string
	map1 := list.ToMap()
	for k, v := range map1 {
		for _, c = range checked {
			if c==k {
				v.Selected=true
				break
			}
		}
		if v.ParentId=="" {
			root.AddChild(map1[k])
		}else{
			parent, exists = map1[v.ParentId]
			if exists {
				parent.AddChild(map1[k])
			}else{
				root.AddChild(map1[k])
			}
		}
	}
	if sort && root.Children!=nil {
		root.Children.DeepSort()
	}
	return root
}
{{ end }}
