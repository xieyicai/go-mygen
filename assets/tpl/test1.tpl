{{- $isTree := 0 }}
{{- range $j, $row := .Fields}}
    {{- if eq $row.Name "ParentId"}}
        {{- $isTree = add $isTree 1 }}
    {{- else if eq $row.Name "Sort"}}
        {{- $isTree = add $isTree 1 }}
    {{- end}}
{{- end -}}
package models

import (
	"strconv"
	"testing"
	"time"
)

func Test{{.StructTableName}}GetRows(tst *testing.T) {
	rows, err := Get{{.StructTableName}}().GetRows("select "+Get{{.StructTableName}}().GetColumns()+" from "+Table{{.StructTableName}}+" where del_flag=?", 0)
	if err != nil {
		tst.Errorf("查询失败。%v\r\n", err)
	} else {
		PrintJson(rows)
	}
}

func Test{{.StructTableName}}GetRow(tst *testing.T) {
	row, err := Get{{.StructTableName}}().GetRow("select "+Get{{.StructTableName}}().GetColumns()+" from "+Table{{.StructTableName}}+" where del_flag=? limit 1", 0)
	if err != nil {
		tst.Errorf("获取单行数据失败。%v\r\n", err)
	} else {
		PrintJson(row)
	}
}

func Test{{.StructTableName}}Create(tst *testing.T) {
	in := &{{.StructTableName}}{
		{{- $pkName := .PrimaryKey}}
		{{- range $j, $row := .Fields}}
		{{- if eq $row.DbOriField $pkName}}
			{{- if eq $row.Type "string"}}
				{{$row.Name}}:	strconv.FormatInt(time.Now().UnixNano(), 36),	{{$row.Remark}}
			{{- else}}
				{{$row.Name}}:	time.Now().Unix(),	{{$row.Remark}}
			{{- end}}
		{{- else if eq $row.Type "float64"}}
			{{$row.Name}}:	0.0,	{{$row.Remark}}
		{{- else if eq $row.Type "float"}}
			{{$row.Name}}:	0.0,	{{$row.Remark}}
		{{- else if eq $row.Type "int64"}}
			{{$row.Name}}:	0,	{{$row.Remark}}
		{{- else if eq $row.Type "int"}}
			{{$row.Name}}:	0,	{{$row.Remark}}
		{{- else if eq $row.Type "time.Time"}}
			{{$row.Name}}:	time.Now(),	{{$row.Remark}}
		{{- else if eq $row.Type "*Time"}}
			{{$row.Name}}:	NewTime(time.Now()),	{{$row.Remark}}
		{{- else}}
			{{$row.Name}}:	"测试数据。",	{{$row.Remark}}
		{{- end}}
		{{- end}}
	}
	err := Get{{.StructTableName}}().Create(in)
	if err != nil {
		tst.Errorf("插入失败。%v\r\n", err)
	} else {
		tst.Logf("插入成功。\r\n")
	}
}

func Test{{.StructTableName}}Save(tst *testing.T) {
	rows, err := Get{{.StructTableName}}().Save("delete from "+Table{{.StructTableName}}+" where create_date>? and description=?", time.Date(2020, 6, 15, 14, 23, 4, 0, time.Local), "测试数据。")
	if err != nil {
		tst.Errorf("删除失败。%v\r\n", err)
	} else {
		tst.Logf("删除了%d行数据。\r\n", rows)
	}
}

func Test{{.StructTableName}}Update(tst *testing.T) {
	if up, err := Get{{.StructTableName}}().First(); err!=nil {
		tst.Fatalf("无法获取一条数据。%v\r\n", err)
	}else{
		up.UpdateDate = NewTime(time.Now())
		rows, err := Get{{.StructTableName}}().Update(up)
		if err != nil {
			tst.Errorf("更新失败。%v\r\n", err)
		} else {
			tst.Logf("更新了%d行数据。\r\n", rows)
		}
	}
}

func Test{{.StructTableName}}All(tst *testing.T) {
	rows, err := Get{{.StructTableName}}().All()
	if err != nil {
		tst.Errorf("查询失败。%v\r\n", err)
	} else {
		PrintJson(rows)
	}
}

func Test{{.StructTableName}}Last(tst *testing.T) {
	row, err := Get{{.StructTableName}}().Last()
	if err != nil {
		tst.Errorf("无法获取最后一行数据。%v\r\n", err)
	} else {
		PrintJson(row)
	}
}

func Test{{.StructTableName}}Count(tst *testing.T) {
	amount, err := Get{{.StructTableName}}().Count()
	if err != nil {
		tst.Errorf("查询数据量失败。%v\r\n", err)
	} else {
		tst.Logf("总共有%d行数据。\r\n", amount)
	}
}

func Test{{.StructTableName}}Exists(tst *testing.T) {
	value := "4"
	has, err := Get{{.StructTableName}}().Exists(value)
	if err != nil {
		tst.Errorf("查询失败。%v\r\n", err)
	} else if has {
		tst.Logf("存在主键为“%s”的数据。\r\n", value)
	} else {
		tst.Logf("不存在主键为“%s”的数据。\r\n", value)
	}
}

func Test{{.StructTableName}}Find(tst *testing.T) {
	where:=&{{.StructTableName}}{ParentId: "1"}
	rows, err := Get{{.StructTableName}}().Find(where)
	if err != nil {
		tst.Errorf("查询失败。%v\r\n", err)
	} else {
		PrintJson(rows)
		rows, err = Get{{.StructTableName}}().Find(" (parent_id is null or parent_id='') and del_flag=?", 0)
		if err != nil {
			tst.Errorf("查询失败。%v\r\n", err)
		} else {
			PrintJson(rows)
		}
	}
}

func Test{{.StructTableName}}Delete(tst *testing.T) {
	where:=&{{.StructTableName}}{DelFlag: 1}
	rows, err := Get{{.StructTableName}}().Delete(where)
	if err != nil {
		tst.Errorf("删除失败。%v\r\n", err)
	} else {
		tst.Logf("删除了“%d”条数据。\r\n", rows)
		rows, err = Get{{.StructTableName}}().Delete("del_flag=?", 1)
		if err != nil {
			tst.Errorf("删除失败！%v\r\n", err)
		} else {
			tst.Logf("删除了“%d”条数据。\r\n", rows)
		}
	}
}

func Test{{.StructTableName}}DeleteById(tst *testing.T) {
	rows, err := Get{{.StructTableName}}().DeleteById("loasanegvn","sadflasn","923j83kd")
	if err != nil {
		tst.Errorf("删除失败。%v\r\n", err)
	} else {
		tst.Logf("删除了“%d”条数据。\r\n", rows)
	}
}

{{- /* 为树结构生成一些函数 */}}
{{ if ge $isTree 2}}
func Test{{.StructTableName}}Len(tst *testing.T) {
	list1 := {{.StructTableName}}List{
		&{{.StructTableName}}{Id:"aa", ParentId:"", Sort:10},
		&{{.StructTableName}}{Id:"bb", ParentId:"aa", Sort:10},
		&{{.StructTableName}}{Id:"cc", ParentId:"bb", Sort:10},
		&{{.StructTableName}}{Id:"dd", ParentId:"cc", Sort:10},
		&{{.StructTableName}}{Id:"dd1", ParentId:"dd", Sort:40},
		&{{.StructTableName}}{Id:"dd2", ParentId:"dd", Sort:30},
		&{{.StructTableName}}{Id:"dd3", ParentId:"dd", Sort:20},
		&{{.StructTableName}}{Id:"dd4", ParentId:"dd", Sort:10},
	}
	if list1.Len()!=8 {
		tst.Errorf("数组的长度为何是%d呢？\r\n", list1.Len())
	}
}

func Test{{.StructTableName}}Less(tst *testing.T) {
	list1 := {{.StructTableName}}List{
		&{{.StructTableName}}{Id:"aa", ParentId:"", Sort:10},
		&{{.StructTableName}}{Id:"bb", ParentId:"aa", Sort:10},
		&{{.StructTableName}}{Id:"cc", ParentId:"bb", Sort:10},
		&{{.StructTableName}}{Id:"dd", ParentId:"cc", Sort:10},
		&{{.StructTableName}}{Id:"dd1", ParentId:"dd", Sort:40},
		&{{.StructTableName}}{Id:"dd2", ParentId:"dd", Sort:30},
		&{{.StructTableName}}{Id:"dd3", ParentId:"dd", Sort:20},
		&{{.StructTableName}}{Id:"dd4", ParentId:"dd", Sort:10},
	}
	if list1.Less(1,0) {
		tst.Errorf("为什么“%s”比“%s”小呢？\r\n", list1[1].Id, list1[0].Id)
	}
	if list1.Less(4,5) {
		tst.Errorf("为什么“%d”比“%d”小呢？\r\n", list1[4].Sort, list1[5].Sort)
	}
}

func Test{{.StructTableName}}Swap(tst *testing.T) {
	list1 := {{.StructTableName}}List{
		&{{.StructTableName}}{Id:"aa", ParentId:"", Sort:10},
		&{{.StructTableName}}{Id:"bb", ParentId:"aa", Sort:10},
		&{{.StructTableName}}{Id:"cc", ParentId:"bb", Sort:10},
		&{{.StructTableName}}{Id:"dd", ParentId:"cc", Sort:10},
		&{{.StructTableName}}{Id:"dd1", ParentId:"dd", Sort:40},
		&{{.StructTableName}}{Id:"dd2", ParentId:"dd", Sort:30},
		&{{.StructTableName}}{Id:"dd3", ParentId:"dd", Sort:20},
		&{{.StructTableName}}{Id:"dd4", ParentId:"dd", Sort:10},
	}
	list1.Swap(0,1)
	if list1[0].Id!="bb" || list1[1].Id!="aa" {
		tst.Errorf("对调失败，list1[0].Id=%s, list1[1].Id=%s\r\n", list1[0].Id, list1[1].Id)
	}
}

func Test{{.StructTableName}}ToMap(tst *testing.T) {
	list1 := {{.StructTableName}}List{
		&{{.StructTableName}}{Id:"aa", ParentId:"", Sort:10},
		&{{.StructTableName}}{Id:"bb", ParentId:"aa", Sort:10},
		&{{.StructTableName}}{Id:"cc", ParentId:"bb", Sort:10},
		&{{.StructTableName}}{Id:"dd", ParentId:"cc", Sort:10},
		&{{.StructTableName}}{Id:"dd1", ParentId:"dd", Sort:40},
		&{{.StructTableName}}{Id:"dd2", ParentId:"dd", Sort:30},
		&{{.StructTableName}}{Id:"dd3", ParentId:"dd", Sort:20},
		&{{.StructTableName}}{Id:"dd4", ParentId:"dd", Sort:10},
	}
	map1:=list1.ToMap()
	PrintJson(map1)
	if map1["dd4"]!=list1[len(list1)-1] {
		tst.Fatalf("失败。\r\n%+v-----------------------\r\n%+v\r\n", map1["dd4"], list1[len(list1)-1])
	}
}

func Test{{.StructTableName}}ToTree(tst *testing.T) {
	list1 := {{.StructTableName}}List{
		&{{.StructTableName}}{Id:"aa", ParentId:"", Sort:10},
		&{{.StructTableName}}{Id:"bb", ParentId:"aa", Sort:10},
		&{{.StructTableName}}{Id:"cc", ParentId:"bb", Sort:10},
		&{{.StructTableName}}{Id:"dd", ParentId:"cc", Sort:10},
		&{{.StructTableName}}{Id:"dd1", ParentId:"dd", Sort:40},
		&{{.StructTableName}}{Id:"dd2", ParentId:"dd", Sort:30},
		&{{.StructTableName}}{Id:"dd3", ParentId:"dd", Sort:20},
		&{{.StructTableName}}{Id:"dd4", ParentId:"dd", Sort:10},
	}
	root:=list1.ToTree(true, "dd3", "dd4")
	PrintJson(root)
	if root.Children[0].Children[0].Children[0].Children[0].Children[0].Id!="dd4" {
		tst.Fatalf("失败。%s\r\n", root.Children[0].Children[0].Children[0].Children[0].Children[0].Id)
	}
}

func Test{{.StructTableName}}GetTree(tst *testing.T) {
	where:=&{{.StructTableName}}{ParentId: ""}
	root, err := Get{{.StructTableName}}().GetTree(where, true, "1", "2")
	if err != nil {
		tst.Errorf("无法生成树结构。%v\r\n", err)
	} else {
		PrintJson(root)
	}
}
{{ end }}